# Hobo Admin Design System

Hobo Admin is a React SPA built with Vite and TailwindCSS v4, serving as the administrative interface for the Hobo application. The visual language is defined by a **dark sidebar + light content area** contrast pattern that provides clear spatial hierarchy and reduces cognitive load for data-heavy admin workflows.

## Design Principles

- **Contrast-Driven Hierarchy** -- The dark sidebar (`#0f1117`) anchors navigation, while the light surface (`#f8f9fc`) gives content maximum readability.
- **Minimalist Data Density** -- Generous whitespace paired with compact typography keeps information scannable without feeling sparse.
- **Subtle Depth** -- Shadows are small and tinted (`shadow-indigo-500/20`), borders are near-invisible (`slate-100`, `slate-200`), and color fills use low opacity (`/15`, `/30`) to avoid visual noise.
- **Typographic Personality** -- Two carefully chosen typefaces (Syne for headings, DM Mono for system labels) create a modern, technical aesthetic.

## Index

### Foundations
- [Colors](foundations/colors.md)
- [Typography](foundations/typography.md)
- [Spacing & Layout](foundations/spacing.md)
- [Shadows](foundations/shadows.md)
- [Borders](foundations/borders.md)
- [Border Radius](foundations/border-radius.md)
- [Icons](foundations/icons.md)
- [CSS Variables Reference (Tokens)](foundations/tokens.md)

### Components
- [Badge](components/badge.md)
- [Avatar](components/avatar.md)
- [StatCard](components/stat-card.md)
- [Button](components/button.md)
- [Table](components/table.md)
- [Card / Panel](components/card-panel.md)
- [SearchBox](components/search-box.md)
- [Form Input](components/form-input.md)

### Layouts
- [Page Layout](layouts/page-layout.md)
- [Navigation](layouts/navigation.md)
- [Page Header Pattern](layouts/page-header.md)

### Implementation
- [Implementation Checklist](checklist.md)

