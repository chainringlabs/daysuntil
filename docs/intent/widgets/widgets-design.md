---
parent: high-level-design
prefix: WIDGET
---

# Widgets

## Context and Design Philosophy

Widgets are where DaysUntil is read. The widget extension is a separate process that the
system launches when it wants something to draw; the app is usually not running. So a
widget has to be right on its own: correct after midnight, correct when the milestone it
shows has been edited or removed, honest when it cannot read anything, and never blank.

The extension reads the store and never writes to it.

Code: `Widgets/` for the widget kinds and their views; the decision of what a widget
shows is plain logic in `Packages/DaysUntilCore/Sources/DaysUntilCore/WidgetContent.swift`
so it can be tested without WidgetKit.

## Widget kinds

| Kind | Sizes | Configured by | Shows |
|---|---|---|---|
| **Milestone** | small, medium, large | The person, per widget: a milestone and a style | One milestone as a face. |
| **Upcoming** | medium, large | Nothing | A list of milestones in display order: three rows at medium, seven at large. |

Each kind has a stable identifier (`MilestoneWidget`, `UpcomingWidget`). Changing one
orphans every widget of that kind already on a desktop.

## Milestone widget

### Configuration

Editing a Milestone widget offers two choices.

- **Milestone**: a list of all non-archived milestones in display order, by title. It can
  also be left unchosen.
- **Style**: number, bar, ring or dots. Number by default.

The widget stores the chosen milestone's id, not a copy of it. A new widget has no
milestone chosen.

### What it shows

What a Milestone widget shows is decided from three things: whether the store could be
read, the chosen milestone id (if any), and the non-archived milestones.

| Situation | Shown |
|---|---|
| The store cannot be opened or read | A message: milestones could not be loaded; open DaysUntil. |
| A milestone is chosen, exists and is not archived | Its face, in the chosen style, at the widget's size, over its theme background. |
| A milestone is chosen but has been deleted or archived | A message: the milestone was removed; edit the widget to pick another. |
| No milestone chosen, at least one non-archived milestone exists | The **next milestone** (first in display order; see Counting), as a face. |
| No milestone chosen, none exist | A message: add a milestone in DaysUntil. |

A widget with no milestone chosen **follows** the next milestone: when that milestone
passes, or a sooner one is added, the widget moves to whichever is next at that moment.
A widget with a chosen milestone never changes to a different one by itself.

Because the system forgets a chosen milestone it can no longer look up, the list the
configuration is resolved against answers for every id it is asked about: a real
milestone when the id exists, a stand-in titled "Removed milestone" when it does not. The
stand-in keeps the choice in place so the widget can say the milestone was removed. When
the store cannot be read, every id asked about gets the stand-in for the same reason: the
choice must survive a failed read, and the widget itself shows the "could not be loaded"
message meanwhile.

Messages are an icon and one line of text on the system's standard widget background.

Clicking a Milestone widget that shows a face opens the app at that milestone, through
the milestone's deep link.

### Timeline

A timeline has an entry for now and one for every instant in the refresh schedule (see
Counting) for the milestones the widget could show: the chosen milestone, or all
non-archived milestones when none is chosen. What to show is decided again for each
entry at that entry's time, so a widget following the next milestone moves on at the
right instant without the app being involved. When the last entry is reached the system
asks for a new timeline.

A widget showing a message asks to be refreshed after 15 minutes as well as whenever the
app reloads timelines, so a failed read recovers by itself.

A timed milestone's final day and first day past are drawn as a live clock by its face,
so the count keeps moving between entries.

## Upcoming widget

Rows are the non-archived milestones in display order, cut to the row limit. Because
display order puts upcoming milestones first and past ones after, a short list of
upcoming milestones is followed by the most recent count-ups.

Each row shows the symbol on a small chip in the milestone's theme colours, the title,
and the count's value and label, with the same live clock as a face when the milestone is
in its final day or first day past. Rows keep the same height whether or not the list is
full. Clicking a row opens the app at that milestone.

Its timeline has an entry for now and for every instant in the refresh schedule across
all non-archived milestones, and the list is re-sorted at each entry so a milestone that
passes moves below the upcoming ones without the app being involved.

With no milestones it shows the "add a milestone" message, and when the store cannot be
read the "could not be loaded" message, as the Milestone widget does, with the same
15-minute refresh.

## The widget gallery and placeholders

While the system is loading a widget, and in the widget gallery when the person has no
milestones yet, widgets show sample milestones so the gallery demonstrates what the
widget looks like instead of an instruction.

## Reading the store

- Each timeline request opens the store if it is not already open. A failed open is not
  remembered: the next request tries again.
- Each read uses a fresh context, so a long-running extension process does not serve
  stale data.
- The app asks the system to reload all widget timelines after every write (see App
  window). This is what makes an edit, archive or delete appear promptly.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| What a widget stores | The milestone's id and a style | A copy of the milestone | A copy would go stale on every edit. |
| Widget with no milestone chosen | Follows the next milestone | Shows an instruction to configure; fixes on whichever milestone was next when it was added | The most likely wish for a new widget is "show my next thing", and following keeps that true with no upkeep. Fixing silently would make a zero-setup widget go stale. |
| Deleted or archived chosen milestone | Say so and ask the person to pick another | Fall back to following the next milestone; keep showing the last known data | The person chose a specific milestone for this widget; replacing it with another shows something nobody chose, and stale data is wrong. |
| Keeping a removed choice visible | A stand-in entry for unknown ids | Accept that the system clears the choice | Without the stand-in a removed milestone is indistinguishable from "none chosen", and the widget would switch silently. |
| Archived treated as removed | Yes | Keep showing archived milestones on widgets | Archiving means "out of sight"; a widget is the most in-sight place there is. |
| Unreadable store | Its own message, distinct from "removed" and "none" | Treat as empty; treat as removed | Telling someone their milestone was removed, or that they have none, when the data is intact sends them to fix the wrong thing. |
| Failed store open | Retried on the next request, and messages refresh after 15 minutes | Open once per process | A single transient failure must not pin a widget on a message. |
| Timeline entries | At each instant in the refresh schedule, content decided per entry | Fixed interval; content decided once per timeline | Counts change at known instants; deciding per entry lets a following widget and the list re-sort exactly then. |
| Upcoming widget contents | Display order, including past milestones after upcoming ones | Upcoming milestones only | Count-ups are milestones too, and a person with two countdowns still gets a full widget. |
| Upcoming widget configuration | None | A choice of which milestones or how many | Keeps the kind zero-setup; the Milestone widget is the configurable one. |
| Gallery with no milestones | Sample milestones | The "add a milestone" message | The gallery is where a person decides whether to add the widget. |

## Open Questions & Future Decisions

### Deferred

1. The name "Upcoming" describes the common case, but the list can include past
   milestones. Whether the kind should be renamed in the gallery, or the list restricted,
   is undecided.
2. The stand-in for a removed milestone relies on the system keeping a configured choice
   whenever the list answers for its id. That is observed behaviour, not a documented
   guarantee.
3. Lock Screen, StandBy and other widget families are out of scope while macOS is the
   only platform.

## References

- `docs/high-level-design.md` — approach (*the desktop widget is the product*), key
  decision on timelines.
- `docs/intent/counting/counting-design.md` — display order, next milestone, refresh
  schedule, final day.
- `docs/intent/faces/faces-design.md` — what a face draws.
- `docs/intent/store/store-design.md` — reads and failure.
