---
parent: high-level-design
prefix: THEME
---

# Themes

## Context and Design Philosophy

A theme is the look of one milestone: the colour its face sits on and the colours drawn
on top. Themes are a fixed, curated list. A person picks one; they never pick a colour.
This follows the HLD tenet *opinionated over configurable*, and it is what allows a
guarantee no colour picker could make: every face is legible.

Code: `Packages/DaysUntilCore/Sources/DaysUntilCore/Theme.swift` (definitions, no UI
imports) and `Sources/DaysUntilUI/Theme+Color.swift` (conversion to SwiftUI colours).

## What a theme is

| Part | Used for |
|---|---|
| `id` | Stored on the milestone. Lowercase, stable. |
| `name` | Shown as the swatch's tooltip and accessibility label. |
| background top / bottom | A two-stop gradient from top-leading to bottom-trailing behind the face. |
| ink | All text. Primary text (title, value) is drawn at full strength; secondary text (labels, dates, percentages, legends) at one fixed reduced opacity, 80%. |
| accent | The filled part of bars, rings and dots, and the symbol. |
| track | The unfilled part of bars, rings and dots. Derived: ink at 20% opacity. |

A theme's colours are the same in light and dark mode. A face carries its own
background, so there is no surrounding surface for it to match.

## The built-in themes

In picker order: Ember, Tide, Moss, Plum, Dune, Frost, Slate, Ink. Six are dark
backgrounds with light ink; Dune and Frost are light backgrounds with dark ink. Ember is
the default for a new milestone.

## Contrast

Every theme must meet, against **both** of its background stops:

- ink at full strength: at least 4.5:1 (WCAG AA for body text);
- ink **as drawn for secondary text**, that is, blended over the background at the
  secondary opacity: at least 4.5:1, because that is the smallest text on a face;
- accent: at least 3:1 (WCAG AA for graphics and large text), because it is used for
  marks and the symbol, never for small text.

Ratios use the WCAG relative-luminance formula. The secondary opacity is a single value
defined beside the themes, and faces use that value and no other for dimmed text, so
what is tested is what is drawn. The rule is enforced by a test that runs over every
theme, so a new or adjusted theme cannot be added without passing it.

The default theme is named explicitly (Ember); it does not depend on the order of the
list.

## Unknown ids

Looking up an id that matches no theme returns the default theme. A stored milestone
therefore survives a theme being renamed or removed: it changes colour, it does not
break.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| How looks are chosen | Fixed list of named themes | Free colour picker; per-part colour settings | Guarantees legibility and keeps the editor to one row of swatches. |
| Light / dark behaviour | One set of colours per theme | Light and dark variants | A face has its own background; adapting would change a colour the person chose when the system appearance flips. |
| Contrast thresholds | 4.5:1 ink, 3:1 accent, both stops | Check against the gradient midpoint; a single threshold | Text can sit over either end of the gradient, and the accent is never used for small text. |
| Dimmed text | One secondary opacity, itself held to 4.5:1 | Several opacities chosen per label; check only full-strength ink | Small dimmed text is where legibility actually fails. One shared value makes the check cover every use. |
| Unknown theme id | Fall back to the default theme | Fail to load the milestone; store colours on the milestone | A cosmetic mismatch must never cost someone a milestone. |
| Where colour values live | As plain RGB values without UI imports | SwiftUI `Color` in the definitions; asset catalog colours | Keeps the contrast rule testable as arithmetic and lets logic code name a theme without importing UI. |

## Open Questions & Future Decisions

### Deferred

1. Track contrast is not checked. At 20% of ink it is deliberately faint, and whether
   unfilled dots are visible enough on every theme has only been judged by eye.
2. The accent is also used for the symbol in the face header, at text size, under a rule
   that only requires 3:1.

## References

- `docs/high-level-design.md` — key decision on themes.
- WCAG 2.x contrast ratio definition.
