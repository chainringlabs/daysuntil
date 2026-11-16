@testable import DaysUntilCore
import Foundation
import Testing

@Suite("All-day countdowns")
struct AllDayCountdownTests {
    @Test("Tomorrow is one day away at any hour today", arguments: [0, 9, 23])
    func tomorrowIsOneDay(hour: Int) {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 17))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, hour, 59))
        #expect(countdown.phase == .upcoming)
        #expect(countdown.days == 1)
    }

    @Test("The target day reads as today")
    func targetDayIsToday() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 16))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 18))
        #expect(countdown.phase == .today)
        #expect(countdown.days == 0)
        #expect(countdown.text.value == "Today")
    }

    @Test("A passed target flips to counting up")
    func pastCountsUp() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 1))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 8))
        #expect(countdown.phase == .past)
        #expect(countdown.days == 15)
        #expect(countdown.text.sentence == "15 days since")
    }

    @Test("Spring-forward does not lose a day")
    func springForward() {
        // DST starts 2027-03-14 in New York; that day is 23 hours long.
        let milestone = Fixture.milestone(target: Fixture.date(2027, 3, 15))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2027, 3, 13, 23, 30))
        #expect(countdown.days == 2)
    }

    @Test("Fall-back does not gain a day")
    func fallBack() {
        // DST ends 2026-11-01 in New York; that day is 25 hours long.
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 2))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 10, 31, 0, 30))
        #expect(countdown.days == 2)
    }

    @Test("Leap day is counted")
    func leapDay() {
        let milestone = Fixture.milestone(target: Fixture.date(2028, 3, 1))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2028, 2, 28))
        #expect(countdown.days == 2)
    }

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
    @Test("Under a day shows hours and minutes")
    func finalDay() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 17, 9, 0), timed: true)
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 15, 30))
        #expect(countdown.phase == .upcoming)
        #expect(countdown.days == 0)
        #expect(countdown.isFinalDay)
        #expect(countdown.text.sentence == "17h 30m left")
    }

    @Test("A day or more shows whole days")
    func wholeDays() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 19, 9, 0), timed: true)
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 8, 0))
        #expect(countdown.days == 3)
        #expect(countdown.hours == 1)
        #expect(!countdown.isFinalDay)
        #expect(countdown.text.sentence == "3 days until")
    }

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

    @Test("Just passed reads as time ago")
    func justPassed() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 16, 12, 0), timed: true)
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 12, 45))
        #expect(countdown.phase == .past)
        #expect(countdown.text.sentence == "45m ago")
    }
}

@Suite("Progress")
struct ProgressTests {
    @Test("Progress runs from the explicit start to the target")
    func explicitStart() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 11, 26), start: Fixture.date(2026, 11, 6))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16, 13))
        #expect(countdown.totalDays == 20)
        #expect(countdown.elapsedDays == 10)
        #expect(countdown.progress == 0.5)
        #expect(countdown.percentText == "50%")
    }

    @Test("Without a start date, progress runs from creation")
    func createdAtFallback() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 1, 11), created: Fixture.date(2026, 1, 1))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 1, 2))
        #expect(countdown.progress == 0.1)
    }

    @Test("Progress clamps before the start and after the target")
    func clamps() {
        let milestone = Fixture.milestone(target: Fixture.date(2026, 6, 10), start: Fixture.date(2026, 6, 1))
        #expect(Fixture.countdown(milestone, now: Fixture.date(2026, 5, 1)).progress == 0)
        #expect(Fixture.countdown(milestone, now: Fixture.date(2026, 7, 1)).progress == 1)
    }

    @Test("A count-up created after its target has no progress")
    func countUpHasNoProgress() {
        let milestone = Fixture.milestone(target: Fixture.date(2020, 5, 1), created: Fixture.date(2026, 1, 1))
        let countdown = Fixture.countdown(milestone, now: Fixture.date(2026, 11, 16))
        #expect(countdown.progress == nil)
        #expect(countdown.dotGrid(maxDots: 50) == nil)
    }

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
