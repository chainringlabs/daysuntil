@testable import DaysUntilCore
import Foundation
import Testing

@Suite("All-day countdowns")
struct AllDayCountdownTests {
    /// @spec COUNT-ALLDAY-001
    @Test("Tomorrow is one day away at any hour today", arguments: [0, 9, 23])
    func tomorrowIsOneDay(hour: Int) {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 17))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, hour, 59))
        #expect(countdown.phase == .upcoming)
        #expect(countdown.days == 1)
    }

    /// @spec COUNT-ALLDAY-002, COUNT-TEXT-001
    @Test("The target day reads as today")
    func targetDayIsToday() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 16))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 18))
        #expect(countdown.phase == .today)
        #expect(countdown.days == 0)
        #expect(countdown.text.value == "Today")
    }

    /// @spec COUNT-ALLDAY-002, COUNT-TEXT-005
    @Test("A passed target flips to counting up")
    func pastCountsUp() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 1))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 8))
        #expect(countdown.phase == .past)
        #expect(countdown.days == 15)
        #expect(countdown.text.sentence == "15 days since")
    }

    /// @spec COUNT-ALLDAY-003
    @Test("Spring-forward does not lose a day")
    func springForward() {
        // DST starts 2027-03-14 in New York; that day is 23 hours long.
        let milestone = Fixture.milestone(target: Fixture.date(2027, 3, 15))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2027, 3, 13, 23, 30))
        #expect(countdown.days == 2)
    }

    /// @spec COUNT-ALLDAY-003
    @Test("Fall-back does not gain a day")
    func fallBack() {
        // DST ends 2026-11-01 in New York; that day is 25 hours long.
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 2))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 10, 31, 0, 30))
        #expect(countdown.days == 2)
    }

    /// @spec COUNT-ALLDAY-003
    @Test("Leap day is counted")
    func leapDay() {
        let milestone = Fixture.milestone(target: Fixture.date(2028, 3, 1))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2028, 2, 28))
        #expect(countdown.days == 2)
    }

    /// @spec COUNT-TEXT-005, COUNT-TEXT-008
    @Test("Singular and plural day labels")
    func dayLabels() {
        let now = Fixture.date(2026, 11, 16)
        let one = Fixture.countdown(Fixture.milestone(target: Fixture.date(2026, 11, 17)), now: now)
        let many = Fixture.countdown(Fixture.milestone(target: Fixture.date(2026, 12, 25)), now: now)
        #expect(one.text.sentence == "1 day until")
        #expect(many.text.sentence == "39 days until")
        #expect(many.weeksText == "5 weeks, 4 days")
        #expect(one.weeksText == nil)
    }
}

@Suite("Timed countdowns")
struct TimedCountdownTests {
    /// @spec COUNT-TIMED-003, COUNT-TEXT-003
    @Test("Under a day shows hours and minutes")
    func finalDay() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 17, 9, 0), timed: true)
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 15, 30))
        #expect(countdown.phase == .upcoming)
        #expect(countdown.days == 0)
        #expect(countdown.isFinalDay)
        #expect(countdown.text.sentence == "17h 30m left")
    }

    /// @spec COUNT-TIMED-001
    @Test("A day or more shows whole days")
    func wholeDays() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 19, 9, 0), timed: true)
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 8, 0))
        #expect(countdown.days == 3)
        #expect(countdown.hours == 1)
        #expect(!countdown.isFinalDay)
        #expect(countdown.text.sentence == "3 days until")
    }

    /// @spec COUNT-TEXT-002
    @Test("Within the same minute reads as now")
    func now() {
        let target = Fixture.date(2026, 11, 16, 12, 0)
        let countdown = Fixture.countdown(
            Fixture.milestone(target: target, timed: true),
            now: target.addingTimeInterval(20)
        )
        #expect(countdown.phase == .today)
        #expect(countdown.text.value == "Now")
    }

    /// @spec COUNT-TEXT-004
    @Test("Just passed reads as time ago")
    func justPassed() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 16, 12, 0), timed: true)
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 12, 45))
        #expect(countdown.phase == .past)
        #expect(countdown.text.sentence == "45m ago")
    }

    /// @spec COUNT-TIMED-002
    @Test("Now lasts from the target until 60 seconds after it")
    func nowWindow() {
        let target = Fixture.date(2026, 11, 16, 12, 0)
        let milestone = Fixture.milestone(target: target, timed: true)
        func phase(_ offset: TimeInterval) -> Countdown.Phase {
            Fixture.countdown(milestone, now: target.addingTimeInterval(offset)).phase
        }
        #expect(phase(-20) == .upcoming)
        #expect(phase(0) == .today)
        #expect(phase(59) == .today)
        #expect(phase(60) == .past)
    }

    /// @spec COUNT-TEXT-003
    @Test("Under a minute to go reads as less than a minute")
    func underAMinute() {
        let target = Fixture.date(2026, 11, 16, 12, 0)
        let countdown = Fixture.countdown(
            Fixture.milestone(target: target, timed: true), now: target.addingTimeInterval(-30)
        )
        #expect(countdown.text.sentence == "<1m left")
        let underAnHour = Fixture.countdown(
            Fixture.milestone(target: target, timed: true), now: target.addingTimeInterval(-45 * 60)
        )
        #expect(underAnHour.text.sentence == "45m left")
    }

    /// @spec COUNT-TIMED-004, COUNT-TIMED-005
    @Test("The live clock is needed in the final day and the first day past, and only then")
    func liveClock() {
        let target = Fixture.date(2026, 11, 16, 12, 0)
        let timed = Fixture.milestone(target: target, timed: true)
        let finalDay = Fixture.countdown(timed, now: Fixture.date(2026, 11, 16, 8, 0))
        let justPast = Fixture.countdown(timed, now: Fixture.date(2026, 11, 16, 12, 45))
        let duringNow = Fixture.countdown(timed, now: target.addingTimeInterval(10))
        let daysAway = Fixture.countdown(timed, now: Fixture.date(2026, 11, 13, 8, 0))
        let daysPast = Fixture.countdown(timed, now: Fixture.date(2026, 11, 18, 13, 0))
        let allDay = Fixture.countdown(Fixture.milestone(target: Fixture.day(2026, 11, 16)), now: target)

        #expect(finalDay.isFinalDay && !finalDay.isFirstDayPast && finalDay.needsLiveClock)
        #expect(justPast.isFirstDayPast && !justPast.isFinalDay && justPast.needsLiveClock)
        for countdown in [duringNow, daysAway, daysPast, allDay] {
            #expect(!countdown.isFirstDayPast)
            #expect(!countdown.needsLiveClock)
        }
    }
}

@Suite("Progress")
struct ProgressTests {
    /// @spec COUNT-PROG-001, COUNT-PROG-002, COUNT-PROG-005, COUNT-TEXT-007
    @Test("Progress runs from the explicit start to the target")
    func explicitStart() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 26), start: Fixture.date(2026, 11, 6))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 13))
        #expect(countdown.totalDays == 20)
        #expect(countdown.elapsedDays == 10)
        #expect(countdown.progress == 0.5)
        #expect(countdown.percentText == "50%")
    }

    /// @spec COUNT-PROG-001
    @Test("Without a start date, progress runs from creation")
    func createdAtFallback() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 1, 11), created: Fixture.date(2026, 1, 1))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 1, 2))
        #expect(countdown.progress == 0.1)
    }

    /// @spec COUNT-PROG-002
    @Test("Progress clamps before the start and after the target")
    func clamps() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 6, 10), start: Fixture.date(2026, 6, 1))
        #expect(Fixture.countdown(milestone, now: Fixture.date(2026, 5, 1)).progress == 0)
        #expect(Fixture.countdown(milestone, now: Fixture.date(2026, 7, 1)).progress == 1)
    }

    /// @spec COUNT-PROG-004
    @Test("A count-up created after its target has no progress")
    func countUpHasNoProgress() {
        let milestone = Fixture.milestone(target: Fixture.date(2020, 5, 1), created: Fixture.date(2026, 1, 1))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16))
        #expect(countdown.progress == nil)
        #expect(countdown.dotGrid(maxDots: 50) == nil)
    }

    /// @spec COUNT-PROG-004
    @Test("A start on the target day, or a start instant at the target, gives no progress")
    func sameDayHasNoProgress() {
        let now = Fixture.date(2026, 11, 16, 15)
        let addedOnTheDay = Fixture.milestone(target: Fixture.day(2026, 11, 16), created: Fixture.date(2026, 11, 16, 9))
        #expect(Fixture.countdown(addedOnTheDay, now: now).progress == nil)
        let instant = Fixture.date(2026, 11, 20, 10)
        let timed = Fixture.milestone(target: instant, timed: true, start: instant)
        #expect(Fixture.countdown(timed, now: now).progress == nil)
    }

    /// @spec COUNT-TEXT-006
    @Test("Large day counts use the locale's digit grouping")
    func grouping() {
        let milestone = Fixture.milestone(target: Fixture.day(2030, 3, 4))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16))
        #expect(countdown.days == 1204)
        #expect(countdown.text.value == 1204.formatted())
    }

    /// @spec COUNT-STYLE-001
    @Test("Progress styles resolve to number only when there is no progress")
    func styleResolution() {
        let now = Fixture.date(2026, 11, 16)
        let with = Fixture.countdown(
            Fixture.milestone(target: Fixture.day(2026, 12, 1), start: Fixture.day(2026, 11, 1)), now: now
        )
        let without = Fixture.countdown(Fixture.milestone(target: Fixture.day(2020, 5, 1)), now: now)
        for style in FaceStyle.allCases {
            #expect(style.resolved(for: with) == style)
            #expect(style.resolved(for: without) == .number)
        }
    }

    /// @spec COUNT-PROG-003, COUNT-PROG-005
    @Test("Timed progress is measured in seconds")
    func timedProgress() {
        let milestone = Fixture.milestone(
            target: Fixture.date(2026, 11, 16, 20, 0), timed: true, start: Fixture.date(2026, 11, 16, 10, 0)
        )
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 12, 30))
        #expect(countdown.progress == 0.25)
        #expect(countdown.totalDays == 1)
    }
}
