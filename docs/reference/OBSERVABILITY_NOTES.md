# Observability notes — Sentry triage & Render MCP logging

## Sentry: `Rack::Multipart::BoundaryTooLongError` is defense firing, not an app bug

Issues of the form `Rack::Multipart::BoundaryTooLongError: multipart boundary not found within limit` in Sentry are the **CVE-2025-61770 defense** (Rack 2.2.19 / 3.1.17 / 3.2.2, published 2025-10-07) working correctly — not application defects. The guard kills requests whose multipart preamble exceeds ~16 KiB without a valid boundary marker.

### Why every POST trips it

`Rack::MethodOverride#call` calls `req.POST` on every form-looking POST, which pulls in `Rack::Multipart.parse_multipart` and hits the new guard at `rack/multipart/parser.rb:350`. The multipart parser fires on endpoints that have nothing to do with file uploads — including `POST /`.

### Scanner signature

Distinct from legitimate upload errors:

- Method/path: `POST /` or other non-form endpoints
- Content-Type: advertises `multipart/form-data` but sends a malformed body
- User-Agent: generic spoofed Chrome (real browsers never post malformed multipart)
- Geo: residential-proxy exit nodes (misc. countries, small-town US)
- Cadence: 1–3 requests minutes apart per probe, not a flood
- **Users Impacted: 0** (critical indicator)
- Culprit frame: `Rack::Multipart::Parser#handle_fast_forward`

Motivation: scanner reconnaissance (Nuclei / Nikto / commercial scanners) probing for unpatched Rack versions or WAF parser differentials. Response behavior lets the scanner fingerprint patch level.

### Triage heuristic

| Condition | Action |
|---|---|
| Users Impacted = 0, culprit is `handle_fast_forward`, single-digit events/hour, path is not a real upload endpoint | **Archive/Ignore** in Sentry |
| Users Impacted > 0 (real users hit it) OR rate > ~10/min (DoS signal) | **Investigate** (broken upload flow OR add an IP/path-based throttle rule to `config/initializers/rack_attack.rb`, or rate-limit upstream at CDN/Fail2ban) |
| Noise outgrows one-off archiving | **Suppress via `before_send`** (see below) |

### Suppression snippet (only when one-off archiving is insufficient)

```ruby
# config/initializers/sentry.rb
config.before_send = lambda do |event, hint|
  return nil if hint[:exception].is_a?(Rack::Multipart::BoundaryTooLongError)
  event
end
```

**Threshold rule**: do not pre-emptively suppress. The minimum-effort safe floor is to let individual issues get archived until the count justifies a global filter.

### Related advisories in the same "defense-firing-as-exception" family

- CVE-2025-61770 — preamble size (this one)
- CVE-2025-61772 — per-part header block without CRLFCRLF
- CVE-2026-34829 — no Content-Length streaming upload
- CVE-2026-26961 — parser differential / WAF bypass (greedy boundary)
- CVE-2022-30122 / CVE-2022-44572 — older multipart DoS

Expect a burst of new Sentry issues for several days after every Rack upgrade — security patches that convert "crash server" into "raise exception" are a security win but a Sentry-noise loss.

---

## Render MCP `list_logs` quirks

Several non-obvious behaviors when using the Render MCP tools to investigate prod logs. Surfaced during 5-day scanner-traffic investigation.

### 1. Not every service emits `request` logs

The Hobo Todo service (`srv-cmohgnocmk4c738sa610`) only emits `app` and `build` log types — **no `request` stream**. Filters like `type=["request"]` or `statusCode=["404"]` silently return `null`/empty even when the requests did happen, because no request-type log was emitted.

### 2. `statusCode` wildcards do not work

`statusCode=["4*", "5*"]` → empty. Enumerate explicitly: `["400", "401", "403", "404", "500", "502", "503"]`.

### 3. Regex with special characters in `text` / `path` silently fails

Patterns like `(?i)(wp-|\.php|...)` return empty even when matching lines exist. **Use plain substring** (`"RoutingError"`, `"Completed 5"`). For OR logic, run multiple queries.

### 4. `statusCode` label may not exist on non-request streams

`list_log_label_values(label="statusCode")` returning `null` is the canary that there are no request logs at all.

### Investigation recipe

```
1. list_log_label_values(label="type", resource=[serviceId])
   → what log types exist?
2. list_log_label_values(label="statusCode", resource=[serviceId])
   → are request logs available at all? null = no.
```

If `type` is only `["app", "build"]`, skip statusCode/method/path filters entirely.

- For Rails apps, `text=["RoutingError"]` on `type=["app"]` is the most reliable way to surface scanner traffic regardless of log level.
- For real HTTP-level metrics when request logs are absent, use `get_metrics(metricTypes=["http_request_count"], aggregateHttpRequestCountsBy="statusCode")` — this works via the platform metrics, not logs.

### Interpretation rule

**"Empty result from `list_logs` is ambiguous"** — it can mean "no matches" or "filter syntax not supported". When empty + unsure, simplify the filter (drop regex, drop wildcards, drop optional labels) and retry.

_Source findings: `rack-boundarytoolongerror-scanner-signature`, `render-mcp-log-query-quirks` (Apr 18, 2026)._
