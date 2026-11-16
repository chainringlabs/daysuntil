# Faces — Specs

Design: `faces-design.md`. Prefix: `FACE`.

Markers: `[x]` implemented with a test, `[ ]` active gap, `[D]` deferred. Specs ending
*(by hand)* are visual and are verified by looking at `make gallery` output and at
widgets on a desktop, not by an automated test.

A "face" is a milestone drawn in a style (number, bar, ring, dots) at a size (small,
medium, large). A "card" is a face on its theme background, as used in the app.

## Rendering

- [x] **FACE-RENDER-001**: The face views shall render every style at every size for a milestone, producing a card of 170×170 points at small, 356×170 at medium and 356×372 at large.
- [x] **FACE-RENDER-002**: The face views shall render without failure for an all-day milestone with progress, an all-day milestone without progress, a timed milestone in its final day, a timed milestone in its first day past, and a milestone with an emoji symbol.
- [x] **FACE-RENDER-003**: A face shall draw no background of its own; a card shall draw the milestone's theme gradient behind the face with rounded corners. *(by hand)*

## Content

- [x] **FACE-CONTENT-001**: Every face shall show the milestone's symbol and title, and the count's value and label. *(by hand)*
- [x] **FACE-CONTENT-002**: When the requested style is bar, ring or dots and the milestone has no progress, the face shall draw the number style. *(by hand)*
- [x] **FACE-CONTENT-003**: The number face shall show the value as its largest element and the target date. *(by hand)*
- [x] **FACE-CONTENT-004**: The bar face shall show the value, a horizontal bar filled to progress, the percentage and the target date. *(by hand)*
- [x] **FACE-CONTENT-005**: The ring face shall show a circular track filled clockwise from 12 o'clock to progress, with the value and label inside it. *(by hand)*
- [x] **FACE-CONTENT-006**: The dots face shall show the dot grid for the milestone's span at the size's dot limit, the count as a sentence, and the percentage at small size or, from medium up, the dot legend when dots are not single days and the percentage otherwise. *(by hand)*
- [x] **FACE-CONTENT-007**: While progress is zero, the bar face shall show a round cap at the bar's left end and the ring face shall show a dot at 12 o'clock. *(by hand)*
- [x] **FACE-CONTENT-008**: At large size, the number and bar faces shall show a footer with the percentage and the weeks reading, whichever apply, and the target date; the ring face shall show the percentage and target date under the title. *(by hand)*
- [x] **FACE-CONTENT-009**: A face shall keep the value on one line, scaling it down to fit, keep the title to one line (two at large size) and truncate it, and keep the target date to one line, scaling it down and then truncating. *(by hand)*
- [x] **FACE-CONTENT-010**: A face shall show a timed milestone's target date with its time of day, and an all-day milestone's without. *(by hand)*

## Dot layout

- [x] **FACE-DOTS-001**: The dot grid shall choose the column count that gives the largest dot size for the available space, fill dots left to right then top to bottom, and place every dot inside the grid's bounds.

## Live clock

- [x] **FACE-CLOCK-001**: While a timed milestone is in its final day, every face style shall show a system-driven clock counting down to the target instant in place of the static value, with the label `left`. *(by hand)*
- [x] **FACE-CLOCK-002**: While a timed milestone is in its first day past, every face style shall show a system-driven clock counting up from the target instant in place of the static value, with the label `ago`. *(by hand)*

## Colour

- [x] **FACE-COLOUR-001**: In full-colour rendering, a face shall draw the title and value in the theme's ink at full strength, all other text in the theme's ink at the secondary text opacity, filled marks and the symbol in the theme's accent, and unfilled marks in the theme's track colour. *(by hand)*
- [x] **FACE-COLOUR-002**: In any rendering mode other than full colour, a face shall draw with the system's primary colour in place of theme colours, and shall mark the symbol and the filled part of bars, rings and dots as accentable. *(by hand)*

## Accessibility

- [x] **FACE-A11Y-001**: A face shall be a single accessibility element whose label is the title, the count's static value and label, and, where the milestone has progress, the percentage followed by `complete` (for example "Lisbon trip, 23 days until, 63% complete").
