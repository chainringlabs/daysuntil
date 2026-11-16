# Themes — Specs

Design: `themes-design.md`. Prefix: `THEME`.

Markers: `[x]` implemented with a test, `[ ]` active gap, `[D]` deferred.
A theme's "background stops" are the two colours of its background gradient. Contrast
ratios are WCAG 2 contrast ratios.

- [x] **THEME-001**: DaysUntil shall provide exactly these built-in themes, in this order, each with a unique id: Ember, Tide, Moss, Plum, Dune, Frost, Slate, Ink.
- [x] **THEME-002**: DaysUntil shall use Ember as the default theme, identified by its id and not by its position in the list.
- [x] **THEME-003**: If a theme is looked up by an id that matches no built-in theme, then DaysUntil shall return the default theme.
- [x] **THEME-004**: Every built-in theme's ink colour shall have a contrast ratio of at least 4.5:1 against each of its background stops.
- [x] **THEME-005**: Every built-in theme's ink colour, blended over each of its background stops at the secondary text opacity, shall have a contrast ratio of at least 4.5:1 against that stop.
- [x] **THEME-006**: Every built-in theme's accent colour shall have a contrast ratio of at least 3:1 against each of its background stops.
- [x] **THEME-007**: DaysUntil shall define one secondary text opacity, 80%, beside the theme definitions, as the only opacity at which theme ink is drawn for dimmed text.
- [x] **THEME-008**: DaysUntil shall derive a theme's track colour as its ink colour at 20% opacity.
