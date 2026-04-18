# Timezone policy — user-facing vs Admin API gap

## Background

Hobo's user-facing Rails stack wraps requests in `Time.use_zone(current_user.time_zone)` via an `around_action` in `ApplicationController`:

```ruby
around_action :in_time_zone_and_locale, if: :logged_in?
```

Each `User` has a `time_zone` column (NOT NULL, default `"UTC"`). `config.time_zone` is NOT set in `config/application.rb`, so Rails defaults the process-wide zone to UTC.

## The gap

The **Admin JSON API** (`Api::V1::Admin::*`) inherits from a different base controller and has **no equivalent wrapping**. Admin requests run with `Time.zone == UTC` regardless of the admin user's local zone.

Any datetime parsing on the admin path silently misinterprets local-date inputs as UTC:

- `Time.zone.parse("2026-04-11")` → UTC midnight, not JST midnight
- `Date.current`, `end_of_day`, range filters — all UTC-framed

### Symptom

JST user submits `to=2026-04-11` on a date-range filter expecting JST midnight cutoff. Backend compares against UTC `2026-04-11 23:59:59`, which is JST `2026-04-12 08:59:59` — events from the next morning leak into the range.

Symmetric bug on `from=`: misses events from "this morning local" because they're still yesterday UTC.

## Why fixture tests miss this

Fixtures typically store UTC datetimes and test expectations match in the same UTC frame. Real-user reports (or a deliberate test with a non-UTC user) are needed to surface it.

## Policy decision paths

No single right answer — pick based on operating reality:

| Option | Implication |
|---|---|
| Global `config.time_zone = 'Asia/Tokyo'` | Fine if admins + users are all one region. Process-wide. |
| Admin-base `around_action` with per-admin `time_zone` | Parallel to user-side. Requires `time_zone` column on admin user. |
| Admin-base `around_action` hardcoded to JST | Simpler than per-admin zone, fine for single-country ops. |

## Rules when touching admin datetime code

- **First**, check `config/application.rb` for `config.time_zone` and the admin base controller for any `Time.use_zone` wrapper. Know who is (or isn't) pushing the zone.
- A naked date string `"2026-04-11"` is parsed in whatever `Time.zone` is active. That zone must match the user's input frame.
- Don't defer the policy decision to "we'll figure it out when it breaks" — a new admin datetime feature is the right forcing function for picking a path.
- When reporting a zone bug, surface both `from` and `to` symmetric sides — users usually only notice one.

## Known offending patterns

- Event log date-range filters in the admin SPA (feature shipped in `#273`-era work; the underlying timezone gap is tracked in Issue [#286](https://github.com/tetran/Hotwire-ToDo/issues/286) — "管理画面の日付フィルタがタイムゾーンを考慮していない / 管理画面のタイムゾーンポリシー要策定"). The Policy decision paths above will be resolved there.

## Related documents

The full timezone problem surface is split across three docs by layer:

| Doc | Layer | Concern |
|---|---|---|
| `docs/reference/TIMEZONE_POLICY.md` (this doc) | **Zone context** | Admin API lacks the user-side `Time.use_zone` wrapper — `Time.zone == UTC` on every admin request |
| `docs/conventions/USER_UI.md` §「`<input type="date">` の日付フィルタは end_of_day を付ける」 | **Day boundary** | Date-only inputs default to midnight; inclusive-end ranges need `.end_of_day` |
| `docs/reference/EVENT_TRACKING_DESIGN_NOTES.md` §5 | **Day boundary (admin context)** | Same end_of_day pattern in the admin event log filter |

The two classes of bug (zone context vs. day boundary) can co-occur — an admin event log filter can be wrong in BOTH dimensions at once, so fixing one without the other still leaves a silent off-by-`(zone_offset)` or off-by-`23:59:59.999` error.

_Source findings: `rails-admin-timezone-gap-pattern` (Apr 12, 2026)._
