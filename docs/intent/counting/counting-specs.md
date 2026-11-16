# Counting — Specs

Design: `counting-design.md`. Prefix: `COUNT`.

Markers: `[x]` implemented with a test, `[ ]` active gap, `[D]` deferred.
"Counting" below means the logic in `DaysUntilCore`; "supplied calendar" and "supplied
now" are the calendar and moment passed to it.

## Milestone

- [x] **COUNT-MS-001**: Counting shall give every milestone the deep link `daysuntil://milestone/<id>`, where `<id>` is the milestone's UUID string.
- [x] **COUNT-MS-002**: When parsing a URL as a milestone deep link, Counting shall return the milestone id only if the scheme is `daysuntil`, the host is `milestone` and the last path component is a UUID, and shall otherwise return nothing.
- [x] **COUNT-MS-003**: Counting shall treat a milestone's symbol as an emoji, to be drawn as text, when the symbol contains any non-ASCII character, and as an SF Symbol name otherwise.

## Calendar days

- [x] **COUNT-DAY-001**: Counting shall read the target date and start date of an all-day milestone as a calendar day, taken as the year, month and day of the stored instant in UTC, ignoring its time of day.
- [x] **COUNT-DAY-002**: When counting or ordering an all-day milestone, Counting shall place its calendar day at the start of the same year, month and day in the supplied calendar, whatever that calendar's time zone.
- [x] **COUNT-DAY-003**: When making the stored instant for a calendar day, Counting shall produce 00:00 UTC of that year, month and day.
- [x] **COUNT-DAY-004**: When converting a milestone from all-day to timed, Counting shall keep the calendar day and set the supplied time of day in the supplied calendar, for the target date and for the start date if present.
- [x] **COUNT-DAY-005**: When converting a milestone from timed to all-day, Counting shall replace the target date, and the start date if present, with the calendar day each falls on in the supplied calendar.

## All-day distance

- [x] **COUNT-ALLDAY-001**: For an all-day milestone, Counting shall report distance as the number of calendar days between the supplied now's day and the target day in the supplied calendar, unaffected by the time of day of the supplied now.
- [x] **COUNT-ALLDAY-002**: For an all-day milestone, Counting shall report phase `upcoming` when the target day is after the supplied now's day, `today` when it is the same day, and `past` when it is before.
- [x] **COUNT-ALLDAY-003**: For an all-day milestone, Counting shall count a day shortened or lengthened by a daylight-saving change, and a leap day, as exactly one day each.

## Timed distance

- [x] **COUNT-TIMED-001**: For a timed milestone, Counting shall report distance as whole days, then hours, then minutes between the supplied now and the target instant in the supplied calendar, each non-negative.
- [x] **COUNT-TIMED-002**: For a timed milestone, Counting shall report phase `today` from the target instant until 60 seconds after it, `upcoming` before the target instant, and `past` from 60 seconds after it.
- [x] **COUNT-TIMED-003**: While a timed milestone is upcoming and its whole-day distance is zero, Counting shall report it as in its final day.
- [x] **COUNT-TIMED-004**: While a timed milestone is past and its whole-day distance is zero, Counting shall report it as in its first day past.
- [x] **COUNT-TIMED-005**: Counting shall report a milestone as needing a live clock exactly when it is in its final day or its first day past.

## Progress

- [x] **COUNT-PROG-001**: Counting shall measure progress from the milestone's start date when one is set, and otherwise from the instant it was added.
- [x] **COUNT-PROG-002**: For an all-day milestone whose start day is an earlier calendar day than its target day, Counting shall report progress as elapsed calendar days divided by total calendar days from start day to target day, clamped to 0…1.
- [x] **COUNT-PROG-003**: For a timed milestone whose start instant is before its target instant, Counting shall report progress as elapsed seconds divided by total seconds from start to target, clamped to 0…1.
- [x] **COUNT-PROG-004**: If an all-day milestone's start day is the same as or later than its target day, or a timed milestone's start instant is not before its target instant, then Counting shall report no progress, as an absent value and not as zero.
- [x] **COUNT-PROG-005**: Where a milestone has progress, Counting shall also report the span's total days (at least 1) and elapsed days (0…total), using calendar days for an all-day milestone and, for a timed milestone, the span's length in days rounded up and the same fraction of it rounded down.

## Words

- [x] **COUNT-TEXT-001**: While an all-day milestone's phase is `today`, Counting shall give the value `Today` and the label `it's here`.
- [x] **COUNT-TEXT-002**: While a timed milestone's phase is `today`, Counting shall give the value `Now` and the label `it's here`.
- [x] **COUNT-TEXT-003**: While a timed milestone is in its final day, Counting shall give the label `left` and the value as hours and minutes (`17h 30m`), as minutes alone under one hour (`45m`), and as `<1m` under one minute.
- [x] **COUNT-TEXT-004**: While a timed milestone is in its first day past, Counting shall give the label `ago` and the value as hours and minutes, or minutes alone under one hour.
- [x] **COUNT-TEXT-005**: For an upcoming or past milestone that is not in its final day or first day past, Counting shall give the value as the whole-day distance and the label as `day until` or `day since` for a distance of one and `days until` or `days since` otherwise.
- [x] **COUNT-TEXT-006**: Counting shall format a whole-day distance with the current locale's digit grouping.
- [x] **COUNT-TEXT-007**: Where a milestone has progress, Counting shall give a percentage reading rounded down to a whole percent, so that `100%` appears only when progress is complete.
- [x] **COUNT-TEXT-008**: When the whole-day distance is seven or more, Counting shall give a weeks reading in whole weeks and remaining days (`5 weeks, 4 days`), and shall give none below seven.

## Dots

- [x] **COUNT-DOTS-001**: When laying a span of days out as dots within a limit, Counting shall use the smallest of the units day, week (7 days), month (30 days) and year (365 days) whose bucket count, rounded up, is within the limit.
- [x] **COUNT-DOTS-002**: Counting shall fill one dot per completed bucket of elapsed days, and shall fill every dot when elapsed days equal total days.
- [x] **COUNT-DOTS-003**: If a span's bucket count in years exceeds the dot limit, then Counting shall draw exactly the limit's number of dots and fill them in proportion to elapsed over total days, rounded down, filling every dot only when the span is complete.
- [x] **COUNT-DOTS-004**: Where the dot unit is not a day, Counting shall give the legend `1 dot = 1 <unit>`, and shall give no legend when each dot is one day.
- [x] **COUNT-DOTS-005**: If a dot layout is requested with a total below one day, an elapsed value outside 0…total, or a limit below one, then Counting shall clamp each to its nearest valid value.
- [x] **COUNT-DOTS-006**: Counting shall set the dot limit to 70 for the small size, 112 for medium and 196 for large.

## Display order and next milestone

- [x] **COUNT-ORDER-001**: Counting shall order milestones with those whose phase is `upcoming` or `today` first, soonest first, followed by those whose phase is `past`, most recent first.
- [x] **COUNT-ORDER-002**: When ordering, Counting shall position an all-day milestone at the start of its calendar day in the supplied calendar, and shall order milestones at the same position by title.
- [x] **COUNT-ORDER-003**: Counting shall identify the next milestone as the first in display order at the supplied now, and as none when there are no milestones.

## Refresh schedule

- [x] **COUNT-SCHED-001**: When asked for a refresh schedule over a window of N days from the supplied now, Counting shall include each of the next N midnights in the supplied calendar.
- [x] **COUNT-SCHED-002**: When asked for a refresh schedule, Counting shall include, for each timed milestone, every instant after the supplied now and inside the window that is a whole number of calendar days before or after its target instant, the target instant itself, and the instant 60 seconds after the target.
- [x] **COUNT-SCHED-003**: Counting shall return a refresh schedule sorted ascending, without duplicates, and containing no instant at or before the supplied now.

## Styles

- [x] **COUNT-STYLE-001**: When a bar, ring or dots style is requested for a milestone that has no progress, Counting shall resolve the style to number; in every other case it shall resolve to the requested style.

## Samples

- [x] **COUNT-SAMPLE-001**: Counting shall provide sample milestones whose dates are relative to the supplied now, including at least one with progress, one count-up without progress, one timed milestone and one with an emoji symbol.
