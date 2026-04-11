# Avatar

Circular gradient avatar showing user initials.

**Base classes**:
```
flex items-center justify-center rounded-full bg-gradient-to-br font-semibold text-white shrink-0
```

**Size variants**:

| Size | Classes           | Dimensions |
|------|-------------------|------------|
| `sm` | `w-7 h-7 text-xs` | 28px       |
| `md` | `w-9 h-9 text-sm` | 36px       |
| `lg` | `w-11 h-11 text-base` | 44px   |

**Default size**: `md`

**Gradient palette** (selected by `name.charCodeAt(0) % 5`):

| Index | Gradient                          |
|-------|-----------------------------------|
| 0     | `from-indigo-500 to-purple-600`   |
| 1     | `from-cyan-500 to-blue-600`      |
| 2     | `from-emerald-500 to-teal-600`   |
| 3     | `from-orange-500 to-rose-600`    |
| 4     | `from-pink-500 to-fuchsia-600`   |

**Initials logic**: Split name by spaces, take first character of each part, join, uppercase, max 2 characters.

