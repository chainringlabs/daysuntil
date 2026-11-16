---
parent: high-level-design
prefix: FACE
---

# Faces

## Context and Design Philosophy

A face is a milestone drawn: one style, at one size, at one moment. Faces are the only
drawing of a milestone in the product. The app's grid, the editor's preview and the
desktop widgets all use the same views, which is how the HLD goal *what the app previews
is what the desktop shows* is met.

The governing tenet is *glanceable over informative*. Each face has one dominant element
(the count, or the progress mark with the count inside it). Secondary facts are small,
and appear only where the size leaves the dominant element dominant.

Code: `Packages/DaysUntilCore/Sources/DaysUntilUI/`.

## Inputs

A face is drawn from a `Milestone`, a `FaceStyle`, a `FaceSize` and a "now" (the
current time when the caller gives none). It computes the countdown from those in the
current calendar and holds no state. It draws no background of its own.

- **`MilestoneFace`** is the face alone. Widgets place it over the theme background as
  the widget's container background.
- **`MilestoneCard`** is a face on its theme background with rounded corners and padding,
  at a fixed size per `FaceSize` that approximates the macOS widget of that size (170×170,
  356×170, 356×372 points). The app uses cards.

## Styles

A requested style is first **resolved** (see Counting): bar, ring and dots need
progress, and a milestone without progress is drawn as number whatever was asked for.

Every face shows the title with the milestone's symbol, and the count's value and label.
The title and value are primary text; everything else is secondary text at the themes'
secondary opacity (see Themes).

| Style | Dominant element | Also shown |
|---|---|---|
| **Number** | The value, as large as the size allows. | Target date. |
| **Bar** | The value, with a horizontal bar beneath it filled to progress. | Percent complete, target date. |
| **Ring** | A circular track filled clockwise from 12 o'clock to progress, with the value and label inside. | Title beneath (small, large) or beside (medium). |
| **Dots** | A grid of dots, one per day or per bucket, filled to elapsed. | The count as a sentence ("23 days until"), and percent complete or the bucket legend. |

Details that are rules rather than taste:

- A bar at zero progress shows a round cap at its left end; a ring at zero shows a dot
  at 12 o'clock. Zero progress is drawn as "started", not as nothing.
- The dot grid chooses the column count that makes the dots as large as the space allows
  and fills left to right, top to bottom. Every dot lies inside the grid's bounds.
- On small faces the dots footer shows percent; from medium up it shows the legend when
  dots are not single days, otherwise percent.

## Sizes

- **Small** and **large** stack vertically. **Medium** is laid out side by side: number
  puts the title and date left and the value right; ring puts the ring left and the
  title, percent and date right.
- **Large** faces have room for a footer under the dominant element: percent complete
  and the count in weeks (whichever apply), and the target date. Large bar includes the
  bar in that footer; large ring shows percent and date under the title.
- Long values and titles never wrap the value: the value stays on one line and scales
  down; the title is one line (two on large) and truncates.
- The target date is one line. A timed milestone's date includes its time
  ("Dec 9, 2026 at 9:00 AM"); when that does not fit it scales down, then truncates.

## The live clock

A timed milestone in its final day or its first day past (see Counting) is shown with a
running clock in place of the static value: counting down to the target in the final
day, counting up from it in the first day past. The clock is driven by the system, so it
keeps moving in a widget between timeline entries. The label beside it is `left` or
`ago`.

This holds wherever a face shows the count: the hero value in number, bar and ring, and
the count sentence in the dots footer. Outside those two states the value is static text
for the given "now". The accessibility label always uses the static words.

## Colour and system rendering

In full colour a face uses its theme's ink, accent and track.

The system can render a widget tinted or dimmed (for example, desktop widgets fade when a
window is in front). In any rendering mode other than full colour, a face draws with the
system's primary colour instead of theme colours, with the track at reduced opacity, and
marks the accent parts (symbol, filled bar, filled ring, filled dots) as accentable so
the system can tint them separately from the rest. Filled and unfilled dots are separate
layers for that reason.

## Accessibility

A face is a single accessibility element whose label is the title, the count as a
sentence, and percent complete when there is progress: "Lisbon trip, 23 days until, 63%
complete".

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| One set of views for app and widgets | Shared | Separate card views for the app | The preview is a promise about the desktop; shared views keep it by construction. |
| Background ownership | Face draws none; caller supplies it | Face draws its own background | Widgets must hand the background to the system as a container background so it can be removed in tinted modes. |
| Style without progress | Fall back to number | Draw an empty bar or ring; hide the style in pickers | A style is chosen per widget, and the milestone can change underneath it; the face must always have something sensible to draw. |
| Zero progress | Minimum visible mark | Empty track | An empty track reads as "broken" or "not started"; the wait has started. |
| Final day and first day past | System-driven clock, in every style | A timeline entry per minute; static hours and minutes | The system updates a clock for free; per-minute entries would spend the widget's refresh budget, and static text is wrong within a minute. |
| Non-full-colour rendering | Primary colour plus accentable marks | Keep theme colours | Theme colours are designed against the theme background, which the system removes in these modes. |
| Card dimensions | Fixed, matching macOS widget sizes | Flexible cards that fill the grid cell | A card that is the widget's size is an honest preview. |
| Secondary facts on large only | Footer on large faces | Same content at every size | *Glanceable over informative*: only large has room without shrinking the count. |

## Open Questions & Future Decisions

### Deferred

1. Card dimensions are fixed approximations. Actual widget sizes vary with display and
   system settings, so a card is close to, not identical to, the widget.
2. The tinted and dimmed appearances have been confirmed to render but have not been
   tuned style by style.
3. Faces are verified by a test that renders every style at every size, for all-day,
   timed, final-day, past and emoji-symbol milestones, and checks that an image of the
   right dimensions comes out. Nothing compares the image to a reference, so a layout
   regression that still renders is caught only by eye (`make gallery`).
4. The live clock reads as hours, minutes and seconds ("17:30:05"), which is longer than
   the static "17h 30m". Whether it stays legible inside a small ring has not been judged
   on a desktop.

## References

- `docs/high-level-design.md` — tenet *glanceable over informative*; key decision on
  shared faces.
- `docs/intent/counting/counting-design.md` — style resolution, final day, dot bucketing.
- `docs/intent/themes/themes-design.md` — ink, accent, track.
