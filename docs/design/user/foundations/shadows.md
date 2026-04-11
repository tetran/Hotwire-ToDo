# Shadow System

Shadow usage and the recommended tiered scale.

## Current Usage

| Location                         | Value                           |
|----------------------------------|----------------------------------|
| Dropdown menu (`.menu-navigation`) | `0 0 10px rgba(0, 0, 0, 0.3)` |
| Notification                     | `0 0 10px rgba(0, 0, 0, 0.3)`   |
| Search modal                     | `0 4px 20px rgba(0, 0, 0, 0.15)`|

## Recommended Tiered Scale

| Token              | Value                          | Usage                          |
|--------------------|--------------------------------|--------------------------------|
| `--shadow-sm`      | `0 1px 2px rgba(0,0,0,0.08)`   | Subtle card lift (future use)  |
| `--shadow-md`      | `0 0 10px rgba(0,0,0,0.3)`     | Dropdowns, toasts (current)    |
| `--shadow-lg`      | `0 4px 20px rgba(0,0,0,0.15)`  | Modals (current)               |

Keep shadows neutral grey; do not introduce accent-tinted shadows (the admin SPA's `shadow-indigo-500/20` pattern is not part of this design language).

