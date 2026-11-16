# App Window — Specs

Design: `app-window-design.md`. Prefix: `APP`.

Markers: `[x]` implemented with a test, `[ ]` active gap, `[D]` deferred. Specs ending
*(by hand)* are interface behaviour verified manually in the running app.

"The app" is the DaysUntil application process. "The grid" is the main window's list of
milestone cards. "The editor" is the add / edit sheet. "The draft" is the milestone as
currently edited in the editor, not yet stored.

## Window and grid

- [x] **APP-GRID-001**: The app shall have a single window showing the grid. *(by hand)*
- [x] **APP-GRID-002**: If the store cannot be opened, then the app shall show an error in place of the grid and shall make New Milestone unavailable. *(by hand)*
- [x] **APP-GRID-003**: The grid shall show each milestone as a small card, in display order, recomputed at least once a minute while the window is open. *(by hand)*
- [x] **APP-GRID-004**: When the card style control is changed, the grid shall draw every card in that style, shall not change any milestone or widget, and shall remember the style between launches. *(by hand)*
- [x] **APP-GRID-005**: While the Archived toggle is off, the grid shall show only milestones that are not archived; while it is on, only archived ones. *(by hand)*
- [x] **APP-GRID-006**: While the grid shows active milestones and there are none, the app shall show a message that says to add a milestone, says how to add a widget (right-click the desktop, Edit Widgets, DaysUntil), and offers a New Milestone button. *(by hand)*
- [x] **APP-GRID-007**: While the grid shows archived milestones and there are none, the app shall show a message that says how a milestone is archived. *(by hand)*

## Actions

- [x] **APP-ACT-001**: When New Milestone is chosen from the toolbar, the File menu (⌘N) or the empty state, the app shall switch the grid to active milestones and open the editor on a new draft. *(by hand)*
- [x] **APP-ACT-002**: A new draft shall have an empty title, be all-day, have as its target the calendar day 30 days after the supplied now's day, have no start date, and have the default symbol and the default theme.
- [x] **APP-ACT-003**: When a card is clicked, or Edit is chosen from its context menu, the app shall open the editor on that milestone. *(by hand)*
- [x] **APP-ACT-004**: When Duplicate is chosen for a milestone, the app shall store a copy with a new id and the title followed by ` copy`, equal to the original in every other field.
- [x] **APP-ACT-005**: When Archive or Unarchive is chosen for a milestone, the app shall store the opposite archived state for it. *(by hand)*
- [x] **APP-ACT-006**: When Delete is chosen for a milestone, the app shall ask for confirmation, naming the milestone by its stored title and saying that widgets showing it will need another picked, and shall delete the milestone only on confirmation. *(by hand)*

## Editor

- [x] **APP-EDIT-001**: The editor shall allow Add or Save only while the draft's title contains at least one non-whitespace character, and shall store the title with surrounding whitespace removed.
- [x] **APP-EDIT-002**: When Include a time is turned on in the editor, the editor shall keep the draft's calendar day and set its time to 9:00 AM, for the target date and for the start date if present; when it is turned off, the editor shall keep the calendar day and drop the time.
- [x] **APP-EDIT-003**: When Track progress from a start date is turned on, the editor shall set the draft's start date to the earlier of the day the milestone was added and its target day for an all-day draft, and to the earlier of the instant it was added and its target instant for a timed draft; when it is turned off, the editor shall remove the start date.
- [x] **APP-EDIT-004**: The editor shall show one line under the progress toggle that states, for the draft as edited: that progress runs from the day it was added, when there is no start date and the draft has progress; that there is no progress because the date is not after the day it was added and a start date would fix that, when there is no start date and the draft has no progress; that progress runs from the start date, when there is a start date and the draft has progress; and that the start must be before the target, when there is a start date and the draft has no progress.
- [x] **APP-EDIT-005**: The editor shall offer the suggested SF Symbols and a field that accepts an emoji, keeping only the last emoji typed, and shall return to the first suggested symbol when the emoji is cleared. *(by hand)*
- [x] **APP-EDIT-006**: The editor shall offer one swatch per built-in theme, in theme order. *(by hand)*
- [x] **APP-EDIT-007**: The editor shall show a small card and a medium card of the draft that update as it is edited, with a style control whose choice is remembered separately from the grid's, and shall preview an empty title as `Untitled`. *(by hand)*
- [x] **APP-EDIT-008**: While the previewed style is bar, ring or dots and the draft has no progress, the editor shall say under the preview that the number style is shown because there is no progress. *(by hand)*
- [x] **APP-EDIT-009**: When Cancel is chosen in the editor, the app shall close the editor and store nothing. *(by hand)*
- [x] **APP-EDIT-010**: When Delete is chosen in the editor, the app shall ask for confirmation over the open editor; on confirmation it shall delete the milestone and close the editor, and otherwise it shall leave the editor open with the draft unchanged. *(by hand)*
- [x] **APP-EDIT-011**: While the editor is open, the app shall make New Milestone unavailable and shall not replace the draft for any reason other than the person closing the editor. *(by hand)*

## Writing

- [x] **APP-WRITE-001**: When the app adds, saves, duplicates, archives, unarchives or deletes a milestone, it shall save the store immediately and then ask the system to reload all widget timelines. *(by hand)*

## Opening from a widget

- [x] **APP-LINK-001**: When the app is opened with a milestone deep link for a milestone that exists and the editor is not open, the app shall switch the grid to active or archived, whichever contains the milestone, and open the editor on it. *(by hand)*
- [x] **APP-LINK-002**: If the app is opened with a milestone deep link for a milestone that does not exist, or while the editor is open, then the app shall come forward and change nothing else. *(by hand)*
