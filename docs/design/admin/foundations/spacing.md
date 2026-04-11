# Spacing and Layout

Spacing scale, grid system, and content width constraints.

## Spacing Scale (commonly used values)

| Token   | Value   | Usage                                    |
|---------|---------|------------------------------------------|
| `0.5`   | 2px     | Nav item vertical gap (`space-y-0.5`)    |
| `1`     | 4px     | Badge vertical padding                   |
| `1.5`   | 6px     | Subtitle top margin                      |
| `2`     | 8px     | Badge horizontal padding, small gaps     |
| `2.5`   | 10px    | Small button padding, avatar icon gap    |
| `3`     | 12px    | Nav item padding, element gaps           |
| `4`     | 16px    | Sidebar horizontal padding, section margin |
| `5`     | 20px    | Card padding, table cell padding         |
| `6`     | 24px    | Main content padding, page section gap   |
| `8`     | 32px    | Login card padding                       |

## Grid System

- **Stat cards**: `grid grid-cols-2 gap-4 lg:grid-cols-4`
- **Dashboard bottom**: `grid grid-cols-1 gap-4 lg:grid-cols-3` (table `lg:col-span-2`)
- **Page sections**: `space-y-5` or `space-y-6`

## Content Width Constraints

| Context        | Width                     |
|----------------|---------------------------|
| Sidebar        | `w-[220px]` fixed         |
| Login form     | `max-w-sm` (384px)        |
| Main content   | `flex-1` (fluid)          |

