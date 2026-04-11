# Layout System

## Overall Structure

```
+--[Sidebar 220px]--+--[Main Content flex-1]------+
|  #0f1117           |  Header h-14 bg-white       |
|                    |  border-b border-slate-200   |
|  Logo area         |-------------------------------|
|  border-b          |                               |
|                    |  Content area                 |
|  Nav sections      |  p-6                          |
|  py-4              |  bg-[#f8f9fc]                 |
|                    |  overflow-y-auto              |
|  User footer       |                               |
|  border-t          |                               |
+--------------------+-------------------------------+
```

**Root**: `flex min-h-screen bg-[#f8f9fc]`

## Sidebar

- Width: `w-[220px] shrink-0`
- Background: `bg-[#0f1117]`
- Border: `border-r border-[#1e2130]`
- Layout: `flex flex-col` (logo top, nav flex-1, user footer bottom)

**Logo area**:
- Padding: `px-4 py-5`
- Border: `border-b border-[#1e2130]`
- Icon box: `h-8 w-8 rounded-lg bg-[#6366f1] shadow-md shadow-indigo-500/30`

**Nav sections**:
- Container: `py-4`, each section `mb-4 px-3`
- Section label: see [foundations/typography.md](../foundations/typography.md)
- Item list: `space-y-0.5`

**User footer**:
- Border: `border-t border-[#1e2130]`
- Padding: `px-3 py-4`

## Top Header

```
flex h-14 shrink-0 items-center border-b border-slate-200 bg-white px-6
```

Contains: breadcrumb on left, search on right.

## Main Content Area

```
flex-1 overflow-y-auto p-6
```

## Login Page Layout

Full-screen dark background:
```
flex min-h-screen items-center justify-center bg-[#0f1117]
```

Form container: `w-full max-w-sm px-4`

