---
parent: high-level-design
prefix: COUNT
---

# Counting

## Context and Design Philosophy

Counting is the rules of the app with nothing else attached: what a milestone is, how
far away it is, how much of its wait has elapsed, and what words say so. Every number a
person reads in DaysUntil comes from here.

It is pure logic. It imports no UI or storage framework, and it never looks up the
current time or calendar on its own: both arrive as arguments (defaulting to the system's
for convenience at call sites). That is what lets every rule be tested against fixed
dates in a fixed time zone.

The guiding rule is the HLD tenet *calendar meaning over clock precision*: a count should
read the way a person would say it.

Code: `Packages/DaysUntilCore/Sources/DaysUntilCore/` (`Milestone`, `CalendarDay`,
`Countdown`, `CountdownText`, `DotGrid`, `Ordering`, `FaceStyle`, `Samples`).

## The milestone value

`Milestone` is a plain, `Sendable`, hashable value. It is what every other component
passes around.

| Field | Meaning |
|---|---|
| `id` | Stable identity. Widgets and deep links refer to a milestone by it. |
| `title` | What the milestone is called. |
| `targetDate` | What is being counted to or from. A calendar day for an all-day milestone, an instant for a timed one (see Calendar days). |
| `includesTime` | `false`: an all-day milestone, counted in calendar days. `true`: a timed milestone, counted to the minute. |
| `startDate` | Optional. Where progress is measured from. A calendar day or an instant, following `includesTime`. |
| `symbol` | An SF Symbol name, or an emoji. A symbol containing any non-ASCII character is treated as an emoji and drawn as text. |
| `themeID` | The id of one of the built-in themes (see Themes). |
| `sortOrder` | Reserved for manual ordering. Nothing reads it. |
| `isArchived` | Archived milestones are hidden from the main grid and from widgets. |
| `createdAt` | The instant the milestone was added. The fallback start for progress. |

A milestone's deep link is `daysuntil://milestone/<id>`. Parsing accepts only that scheme
and host and returns the id, or nothing.

## Calendar days

An all-day milestone is on a **calendar day**: 9 December is 9 December in every time
zone. It is not an instant, and moving the Mac to another time zone must not move it.

A calendar day is carried in a `Date` field as the instant of 00:00 UTC on that day.
Reading it takes the year, month and day of that instant in UTC and nothing else; the
time of day and the local time zone play no part. To count or display it, the day is
placed in the supplied calendar as that calendar's start of the same year, month and day.

- Reading tolerates any time of day in the stored instant: only its UTC year, month and
  day are used.
- Writers store 00:00 UTC of the intended day.
- This applies to `targetDate` and `startDate` of an all-day milestone. `createdAt` is
  always an instant; when an all-day milestone falls back to it for progress, its day is
  the day that instant falls on in the supplied calendar.

A timed milestone's `targetDate` and `startDate` are ordinary instants.

Switching a milestone between all-day and timed converts its dates so the calendar day a
person sees is preserved (the editor decides the time of day when one is added; see App
window).

## Distance and phase

A `Countdown` is a milestone evaluated at one moment. It has a **phase** and a distance.

- `upcoming` — the target is ahead.
- `today` — the target is now: the target's calendar day for an all-day milestone; from
  the target instant until 60 seconds after it for a timed one.
- `past` — the target has gone by.

**All-day milestones.** Distance is the number of calendar days between today, in the
supplied calendar, and the target day. Time of day never changes it, and a 23- or 25-hour
day at a daylight-saving change counts as one day.

**Timed milestones.** Distance is the whole days, then hours, then minutes between now
and the target, in the supplied calendar. The day part changes at the target's time of
day, not at midnight: at 08:00 a target at 09:00 three days later is "3 days" with one
hour over. When the target is upcoming and the day part is zero, the countdown is in its
**final day**. When the target is past, the day part is zero and the `today` window is
over, it is in its **first day past**. Those two states are the signal for displays to
show a running clock instead of a day count.

## Progress

Progress is the fraction of the span from *start* to *target* that has elapsed, clamped
to 0…1. Start is `startDate` when set, otherwise `createdAt`.

- **All-day.** The span is measured in whole calendar days. There is progress only when
  the start day is an earlier calendar day than the target day; a milestone added on its
  own target day, or after it, has none. Progress moves once a day, at midnight, in step
  with the count.
- **Timed.** The span is measured in seconds, and there is progress only when the start
  instant is before the target instant. Its length in days (rounded up, minimum 1) and
  elapsed days (the same fraction of that length, rounded down) are also exposed so the
  dot style can draw it.
- A milestone without progress has an **absent** value, not zero. This is the normal
  state of a count-up added after the fact ("moved in" two years ago, added today).
- Once the target passes, progress stays at 1.

## Words

`CountdownText` turns a countdown into a **value** (the hero) and a **label**.

| Situation | Value | Label |
|---|---|---|
| All-day, target is today | `Today` | `it's here` |
| Timed, in the minute after the target | `Now` | `it's here` |
| Timed, final day | `17h 30m`; `45m` under an hour; `<1m` under a minute | `left` |
| Timed, first day past | `45m` / `3h 10m` | `ago` |
| Upcoming otherwise | the day count | `day until` / `days until` |
| Past otherwise | the day count | `day since` / `days since` |

These are static readings for one moment. Displays that can run a live clock use one in
the final day and the first day past (see Faces) and fall back to these words elsewhere,
such as accessibility labels.

Day counts are formatted with the locale's grouping (`1,204`). A percentage reading
rounds down, so it shows `100%` only when the span is complete. A weeks reading
("5 weeks, 4 days") exists for counts of seven days or more.

## Dots

`DotGrid` turns a span of days into a number of dots that fits a limit. It uses the
smallest unit (day, week of 7, month of 30, year of 365) whose bucket count is within the
limit. Filled dots are completed buckets, except that a finished span fills every dot
even when its last bucket is partial. When the unit is not a day, a legend
("1 dot = 1 week") says so.

A span too long to fit even in years is drawn with exactly the limit's number of dots,
filled in proportion to elapsed time, so the grid never reads as finished before the
span is.

Months and years are fixed-length buckets, not calendar months. The grid is a picture of
proportion, not a calendar.

## Display order

Milestones are listed with upcoming and today first, soonest first; then past, most
recent first. For ordering, an all-day milestone sits at the start of its day in the
supplied calendar, so it comes before a timed milestone later the same day. Milestones at
the same moment fall back to title order so the list is stable.

The **next milestone** is the first in display order. It is what a widget shows when no
particular milestone has been chosen for it.

## Refresh schedule

`RefreshSchedule` answers "after now, when does any displayed count next change?" for a
set of milestones, within a window of N days (default 5). It returns, sorted and without
duplicates:

- each of the next N midnights in the supplied calendar (all-day counts, and the order
  of the list, change there);
- for each timed milestone, every instant inside the window that is a whole number of
  days before or after its target (its day count changes there, and the final day and
  first day past begin and end there), the target itself, and 60 seconds after the
  target (the end of `Now`).

Between those instants a count either does not change or is in a state displays cover
with a live clock.

## Styles and sizes

`FaceStyle` (number, bar, ring, dots) and `FaceSize` (small, medium, large) are defined
here because both Faces and Widgets need them and they carry rules, not drawing: bar,
ring and dots need progress, so a style **resolves** to number for a countdown without
progress; and each size sets the dot limit (70, 112, 196).

## Samples

`Milestone.samples` returns representative milestones with dates relative to the supplied
"now", for previews, widget placeholders and the widget gallery.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|----------|--------|------------------------|-----------|
| Day counting for all-day milestones | Calendar days | Elapsed seconds ÷ 86,400 | Seconds make "tomorrow" read 0 in the evening and drift across daylight-saving changes. |
| What an all-day date is | A calendar day, fixed across time zones | The instant of local midnight where it was entered | An instant moves to the previous day when the Mac travels west, taking the count with it; a birthday or deadline day does not move. |
| How a calendar day is carried | 00:00 UTC of that day in the existing `Date` field, read by UTC year-month-day only | Separate year, month and day fields; a date string | Needs no change to the stored shape, and reading only the UTC day makes it tolerant of whatever time of day an older value carries. |
| Day counting for timed milestones | Whole days from the current instant | Calendar-day boundaries, as for all-day | A timed milestone exists because the hour matters; the day count should fall at that hour and hand over cleanly to hours and minutes in the final day. |
| `Now` window for timed milestones | The 60 seconds after the target | Symmetric around the target; exact equality | A countdown should reach zero before it says `Now`, and a window that starts at the target needs only two schedule instants. |
| No-progress representation | Absent value | Zero | Zero would draw an empty bar for a milestone that has no span at all; absent lets styles fall back to the number. |
| Progress start fallback | `createdAt` | Require `startDate`; no progress without it | Most countdowns are added when the wait begins. |
| Dot bucket units | Fixed 7 / 30 / 365 days | Calendar weeks, months, years | The grid shows proportion; calendar units would make dot counts depend on which months the span covers. |
| Over-long spans in dots | Limit's worth of dots, filled proportionally | Fill by whole years up to the limit | Filling by years completes the grid before the span is complete. |
| Percentage rounding | Down | Nearest | "100%" should mean finished. |
| Schedule contents | Every instant a count changes | Midnights only; a fixed interval | A timed count changes at its own hour; midnights alone leave it wrong for most of a day. |
| Time and calendar | Passed in, with system defaults | Read inside the logic | Makes every rule testable with fixed dates. |
| Where styles and sizes are defined | Here, as plain enums | In Faces | Widgets needs them for configuration without depending on drawing code, and the fallback rule is logic. |

## Open Questions & Future Decisions

### Deferred

1. `sortOrder` is stored and carried but unused; manual ordering in the app window has
   not been designed.
2. A timed milestone's day part follows the calendar, so across a daylight-saving change
   "1 day" can be 23 or 25 hours and a final day can run to "24h 59m".
3. A timed span's elapsed days are a proportion of its rounded-up length, so a 1.1-day
   span has two dots and fills the first after about 13 hours.
4. A timed milestone's progress changes continuously, but the schedule only lists
   instants at which a count changes. Between them a displayed bar, ring or percentage
   is as of the last refresh.
5. All wording is English and assembled by string interpolation. Localization is an HLD
   non-goal; if that changes, `CountdownText` is where it lands.
6. A span too long to fit in years keeps `year` as its unit, so its legend still reads
   "1 dot = 1 year" although each dot then stands for more than a year. It takes a span
   over 112 years at medium size to show it.

## References

- `docs/high-level-design.md` — tenets, key decisions on direction, day counting, progress.
- `Packages/DaysUntilCore/Tests/DaysUntilCoreTests/` — the rules above as executable cases.
