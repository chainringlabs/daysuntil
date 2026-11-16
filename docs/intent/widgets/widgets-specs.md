# Widgets — Specs

Design: `widgets-design.md`. Prefix: `WIDGET`.

Markers: `[x]` implemented with a test, `[ ]` active gap, `[D]` deferred. Specs ending
*(by hand)* depend on WidgetKit or the desktop and are verified manually.

"The Milestone widget" is the configurable single-milestone widget kind; "the Upcoming
widget" is the list kind. "Chosen milestone" is the milestone id stored in a Milestone
widget's configuration. "Next milestone" is the first non-archived milestone in display
order at a given moment.

## What a Milestone widget shows

- [x] **WIDGET-SHOW-001**: If the store cannot be opened or read, then the Milestone widget shall show the message that milestones could not be loaded, whether or not a milestone is chosen.
- [x] **WIDGET-SHOW-002**: While the Milestone widget's chosen milestone exists and is not archived, the widget shall show that milestone.
- [x] **WIDGET-SHOW-003**: If the Milestone widget's chosen milestone no longer exists or is archived, then the widget shall show the message that the milestone was removed, and shall not show any other milestone.
- [x] **WIDGET-SHOW-004**: While the Milestone widget has no chosen milestone and at least one non-archived milestone exists, the widget shall show the next milestone as of the moment being drawn.
- [x] **WIDGET-SHOW-005**: While the Milestone widget has no chosen milestone and no non-archived milestone exists, the widget shall show the message to add a milestone in DaysUntil.
- [x] **WIDGET-SHOW-006**: When the Milestone widget shows a milestone, it shall draw that milestone's face in the configured style at the widget's size over the milestone's theme background. *(by hand)*
- [x] **WIDGET-SHOW-007**: When a Milestone widget showing a milestone is clicked, the system shall open that milestone's deep link. *(by hand)*

## Configuration

- [x] **WIDGET-CONFIG-001**: The Milestone widget's configuration shall offer every non-archived milestone, in display order, by title, and the styles number, bar, ring and dots with number as the default. *(by hand)*
- [x] **WIDGET-CONFIG-002**: A newly added Milestone widget shall have no chosen milestone. *(by hand)*
- [x] **WIDGET-CONFIG-003**: When the system asks the Milestone widget's configuration to resolve milestone ids, the configuration shall answer for every id asked: with the milestone's title when a milestone with that id exists, and with a stand-in titled `Removed milestone` carrying the same id when none does.

## Timelines

- [x] **WIDGET-TIME-001**: The Milestone widget's timeline shall contain an entry for the current moment and one for every instant in the refresh schedule for its chosen milestone, or for all non-archived milestones when none is chosen, and shall decide what to show separately for each entry at that entry's time. *(by hand)*
- [x] **WIDGET-TIME-002**: When a Milestone or Upcoming widget's timeline shows a message, the widget shall ask to be refreshed after 15 minutes; otherwise it shall ask to be refreshed when its last entry is reached. *(by hand)*
- [x] **WIDGET-TIME-003**: The Upcoming widget's timeline shall contain an entry for the current moment and one for every instant in the refresh schedule for all non-archived milestones, with its rows in display order as of each entry's time. *(by hand)*

## Upcoming widget

- [x] **WIDGET-LIST-001**: The Upcoming widget shall show the non-archived milestones in display order, limited to three rows at medium size and seven at large.
- [x] **WIDGET-LIST-002**: Each Upcoming row shall show the milestone's symbol on a chip in its theme colours, its title, and its count's value and label, using a system-driven clock in place of the value while the milestone is in its final day or first day past. *(by hand)*
- [x] **WIDGET-LIST-003**: The Upcoming widget shall keep rows the same height whether or not the list is full. *(by hand)*
- [x] **WIDGET-LIST-004**: When an Upcoming row is clicked, the system shall open that milestone's deep link. *(by hand)*
- [x] **WIDGET-LIST-005**: While no non-archived milestone exists, the Upcoming widget shall show the message to add a milestone in DaysUntil; if the store cannot be opened or read, then it shall show the message that milestones could not be loaded.

## Gallery and loading

- [x] **WIDGET-GALLERY-001**: While a widget is being previewed in the widget gallery and no non-archived milestone exists, and while the system shows a widget's placeholder, the widget shall show sample milestones. *(by hand)*

## Reading the store

- [x] **WIDGET-STORE-001**: The widget extension shall never write to the store. *(by hand)*
- [x] **WIDGET-STORE-002**: When a timeline is requested and the store is not open, the widget extension shall try to open it, and shall try again on the next request if that fails. *(by hand)*
