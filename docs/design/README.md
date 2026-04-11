# Design Systems

Hobo ships two deliberately distinct design systems — one for the user-facing app (Rails + Hotwire + Water.css, cyan accent) and one for the admin SPA (React + TailwindCSS v4 + Syne/DM Mono, indigo accent). They are split into small per-topic files so Claude (and humans) can load only the sections relevant to the task at hand.

- **[User Design System](user/README.md)** — user-facing app (project dashboard, tasks, comments, notifications, auth)
- **[Admin Design System](admin/README.md)** — admin SPA (dashboard, users, roles, permissions, LLM providers)

The two systems are intentionally different in typography, color, layout, and density. When building an admin feature, follow only `admin/`; when building a user feature, follow only `user/`. Do not mix patterns between them.

