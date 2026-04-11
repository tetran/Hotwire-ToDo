# Project Header

The top header that houses the project selector, search, members menu, and user menu.

Structure (see `projects.css` and `app/views/projects/_header.html.erb`):

```
.project-header                     (flex, space-between, relative)
  .project-selector                 (left — dropdown trigger for switching projects)
    h2.project-name                 (inline)
  .project-header__right            (flex, gap: 0)
    .search-container
    .project-members                (menu button for member management)
    .menu-container--header         (main user menu)
```

The selector dropdown uses `.menu-navigation` positioned `left: 0`; the members/user menu dropdowns use `right: 0`.

