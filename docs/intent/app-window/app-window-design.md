---
parent: high-level-design
prefix: APP
---

# App Window

## Context and Design Philosophy

The app window is where milestones are made and changed. It is visited rarely: to add
something, fix a date, or tidy up. It should make those few tasks obvious to someone who
has never seen it, show exactly what the result will look like on the desktop, and then
get out of the way.

It is the only writer to the store, and it is responsible for telling the system to
redraw widgets whenever it writes.

Code: `App/` for the window and its views; the editor's rules that are plain logic (the
new-milestone draft, title validity, the all-day / timed switch, the progress line) are in
`Packages/DaysUntilCore/Sources/DaysUntilCore/EditorRules.swift` so they can be tested
without the UI.

## Window

There is one window. It shows either the grid of milestones, or, when the store could not
be opened, an error explaining that in place of everything else. With the store
unavailable, creating a milestone is disabled.

```
┌──────────────────────────────────────────────────────────────┐
│ DaysUntil        [Number│Bar│Ring│Dots]         [Archived] [+]│
├──────────────────────────────────────────────────────────────┤
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐              │
│  │ ✈ Trip │  │ 🏃 Race │  │ 📕 Due │  │ 🏠 Home │              │
│  │   23   │  │   96   │  │   9    │  │  412   │              │
│  │ days…  │  │ days…  │  │ days…  │  │ days…  │              │
│  └────────┘  └────────┘  └────────┘  └────────┘              │
└──────────────────────────────────────────────────────────────┘
```

## Grid

- Milestones are shown as small cards (see Faces) in display order (see Counting), in as
  many columns as fit.
- A **card style** control switches every card between number, bar, ring and dots. It
  affects only this window; it is a way to look at milestones, not a property of them.
  The choice is remembered between launches.
- An **Archived** toggle switches the grid between active milestones and archived ones.
  It is never both. Starting a new milestone switches the grid to active milestones, so
  what is added is always in view.
- Cards are recomputed every minute while the window is open, so counts roll over at
  midnight and timed milestones stay current.

### Empty states

- No active milestones: a message saying what to add, how to put a widget on the desktop
  afterwards (right-click the desktop, Edit Widgets, DaysUntil), and a New Milestone
  button. For a first-time user this is the app's entire onboarding.
- Archived view with nothing archived: a message saying how archiving is done.

## Actions on a milestone

| Action | How | Effect |
|---|---|---|
| New | Toolbar **+**, File ▸ New Milestone (⌘N), or the empty state's button | Opens the editor on a draft: empty title, all-day, target 30 days from today, default symbol and theme. Nothing is stored until Add. Unavailable while the editor is open. |
| Edit | Click a card, or its context menu | Opens the editor on that milestone. |
| Duplicate | Context menu | Stores a copy with a new id and " copy" appended to the title. |
| Archive / Unarchive | Context menu | Flips the milestone's archived state. |
| Delete | Context menu, or the editor's Delete button | Asks for confirmation, naming the milestone by its stored title and warning that widgets showing it will need another picked. Deletes on confirm. |

## Editor

A sheet with the form on the left and a live preview on the right.

**Form**

- **Title.** Required. Surrounding whitespace is removed on save. Add / Save is disabled
  while the title is empty or only whitespace.
- **Date**, and **Include a time**. With time off the picker offers a date only, and the
  milestone is on that calendar day (see Counting). Turning time on keeps the day and
  sets the time to 9:00 AM; turning it off keeps the day and drops the time. The start
  date follows the same switch.
- **Track progress from a start date.** Off by default. Turning it on reveals a start
  date picker, starting from the earlier of when the milestone was added and its
  target date. A line under the toggle states what is true of the milestone as edited,
  by the same rule Counting uses: progress runs from the day it was added; progress runs
  from the start date; there is no progress because the date is not after the day it was
  added, and a start date would fix that; or there is no progress because the start is
  not before the target.
- **Symbol.** A grid of suggested SF Symbols, or a field for an emoji instead. The emoji
  field keeps a single emoji: the last one typed. Clearing it returns to the first
  suggested symbol.
- **Theme.** One swatch per built-in theme.

**Preview**

- A small card and a medium card of the milestone as currently edited, with a style
  control. The preview style is remembered separately from the grid's.
- An empty title previews as "Untitled".
- A note under the cards explains the preview when it could surprise: that bar, ring and
  dots are showing the number style because there is no progress; otherwise the count
  restated in weeks, or a reminder that style is chosen per widget.

**Buttons**

- **Add** (new) or **Save** (existing): stores the milestone and closes. Return triggers
  it.
- **Cancel**: closes without storing. Escape triggers it.
- **Delete…** (existing only): asks for confirmation over the editor. Confirming deletes
  the milestone and closes the editor; declining returns to the editor with its edits
  intact.

The editor holds the only unsaved state in the app, so nothing replaces it while it is
open: New is unavailable, and a widget click brings the app forward without changing
what is being edited.

## Writing and widgets

Every write (add, save, duplicate, archive, unarchive, delete) is saved to the store
immediately and followed by a request to the system to reload all widget timelines. There
is no unsaved state outside the editor sheet.

## Opening from a widget

The app registers the `daysuntil` URL scheme. Opening `daysuntil://milestone/<id>` for a
milestone that exists switches the grid to whichever of active or archived contains it and
opens the editor on it. A link to a milestone that does not exist, or one arriving while
the editor is open, does nothing beyond bringing the app forward.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| Window model | One window | A window per milestone; multiple windows | There is one list and nothing to compare side by side. |
| Card style | A view setting for the whole grid | A style stored per milestone | Style belongs to each widget. A per-milestone style would be a third place it could be set and would suggest widgets follow it. |
| What a click does | Opens the editor | Selects the card; opens a detail view | There is nothing to do with a milestone here except change it. |
| Removing from view | Archive and delete are separate | Delete only | A finished countdown is often worth keeping; archive hides it from the grid and widgets without losing it. |
| Delete confirmation | Always | Undo instead; no confirmation | Delete is permanent and also breaks any widget showing the milestone. |
| Delete from the editor | Confirm over the open editor | Close the editor, then confirm | Closing first throws away edits even when the person declines the delete. |
| Interruptions while editing | Ignored | Replace the draft; ask to discard | The draft is the only unsaved state; a stray ⌘N or widget click should not cost it, and a discard prompt is more ceremony than a rare event deserves. |
| Time when "Include a time" is turned on | 9:00 AM on the same day | Midnight; the current time of day | Midnight makes the card count to the very start of the day, which is almost never what a timed milestone means. |
| After starting a new milestone in the archived view | Switch to active | Stay in archived | A milestone that is saved but not shown looks lost. |
| Saving | Immediately on every action | Explicit document save | There is no document; widgets should reflect a change as soon as it is made. |
| New milestone default date | 30 days ahead, all-day | Today; empty | A new card that already shows a plausible countdown explains the app better than "Today". |
| Onboarding | The empty state's text | A first-run walkthrough | The only two things to learn are "add a milestone" and "add a widget"; one paragraph covers both. |
| Store unavailable | Replace the grid with the error | Offer to reset the store | Resetting would delete someone's milestones; the error preserves them for diagnosis. |
| Deep link target | Opens the editor on the milestone | Scrolls to and highlights its card | With one window and click-to-edit, the editor is the milestone's only "place". |

## Open Questions & Future Decisions

### Deferred

1. If saving to the store fails after a change, the app does not tell the person. In a
   release build the change stays in memory and is retried by the framework's autosave,
   so a failure that persists would lose the change on quit without warning; a debug
   build stops at the failure. Widgets are asked to reload either way and are not asked
   again when a later save succeeds.
2. Manual ordering of the grid is not designed. `sortOrder` exists on the milestone for
   it.
3. Duplicating keeps the original's "added" date, so a duplicate's fallback progress
   start is the original's, not the moment of duplication.
4. The widget instructions in the empty state disappear once a milestone exists. A person
   who adds a milestone before reading them has no in-app reminder of how to add a
   widget.
5. The start date picker does not prevent choosing a start on or after the target; it
   explains the consequence instead.
6. A widget click that launches the app from cold relies on the milestone list being
   loaded before the link is handled. It works in use; the ordering is not guaranteed by
   anything in the design.

## References

- `docs/high-level-design.md` — target users, goals on first use and preview fidelity.
- `docs/intent/faces/faces-design.md` — cards.
- `docs/intent/store/store-design.md` — the record and its apply rule.
- `docs/intent/widgets/widgets-design.md` — what widgets do when a milestone is removed.
