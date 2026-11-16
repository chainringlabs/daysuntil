@testable import DaysUntilCore
import Foundation
import Testing

@Suite("Display order")
struct OrderingTests {
    private let now = Fixture.date(2026, 11, 16, 10)

    /// @spec COUNT-ORDER-001
    @Test("Upcoming soonest first, then past most recent first")
    func displayOrder() {
        let far = Fixture.milestone(title: "Far", target: Fixture.day(2027, 6, 1))
        let near = Fixture.milestone(title: "Near", target: Fixture.day(2026, 11, 20))
        let today = Fixture.milestone(title: "Today", target: Fixture.day(2026, 11, 16))
        let old = Fixture.milestone(title: "Old", target: Fixture.day(2020, 1, 1))
        let recent = Fixture.milestone(title: "Recent", target: Fixture.day(2026, 11, 1))
        let sorted = [old, far, recent, near, today].sortedForDisplay(now: now, calendar: Fixture.calendar)
        #expect(sorted.map(\.title) == ["Today", "Near", "Far", "Recent", "Old"])
    }

    /// @spec COUNT-ORDER-002
    @Test("An all-day milestone sorts at the start of its day; equal positions sort by title")
    func positions() {
        // Same calendar day, stored with different times of day: only the day counts.
        let zebra = Fixture.milestone(title: "Zebra", target: Fixture.day(2026, 12, 9))
        let apple = Fixture.milestone(title: "Apple", target: Fixture.date(2026, 12, 9, 5, 0, in: Fixture.utc))
        let morning = Fixture.milestone(title: "Morning", target: Fixture.date(2026, 12, 9, 8, 0), timed: true)
        let sorted = [morning, zebra, apple].sortedForDisplay(now: now, calendar: Fixture.calendar)
        #expect(sorted.map(\.title) == ["Apple", "Zebra", "Morning"])
    }

    /// @spec COUNT-ORDER-003
    @Test("The next milestone is the first in display order, or none")
    func nextMilestone() {
        let near = Fixture.milestone(title: "Near", target: Fixture.day(2026, 11, 20))
        let far = Fixture.milestone(title: "Far", target: Fixture.day(2027, 6, 1))
        let past = Fixture.milestone(title: "Past", target: Fixture.day(2026, 11, 1))
        #expect([far, past, near].nextMilestone(now: now, calendar: Fixture.calendar) == near)
        // Once "Near" has passed, the next one is "Far".
        let later = Fixture.date(2026, 11, 21, 10)
        #expect([far, past, near].nextMilestone(now: later, calendar: Fixture.calendar) == far)
        // With nothing upcoming, the most recent past milestone.
        #expect([past].nextMilestone(now: now, calendar: Fixture.calendar) == past)
        #expect([Milestone]().nextMilestone(now: now, calendar: Fixture.calendar) == nil)
    }
}

@Suite("Refresh schedule")
struct RefreshScheduleTests {
    private let now = Fixture.date(2026, 11, 16, 14)

    /// @spec COUNT-SCHED-001, COUNT-SCHED-003
    @Test("All-day milestones need only the coming midnights")
    func midnights() {
        let allDay = Fixture.milestone(target: Fixture.day(2026, 11, 17))
        let dates = RefreshSchedule.dates(for: [allDay], from: now, days: 3, calendar: Fixture.calendar)
        #expect(dates == [Fixture.date(2026, 11, 17), Fixture.date(2026, 11, 18), Fixture.date(2026, 11, 19)])
    }

    /// @spec COUNT-SCHED-002, COUNT-SCHED-003
    @Test("A timed milestone adds its day marks, its target and the end of Now")
    func timed() {
        let target = Fixture.date(2026, 11, 18, 9, 30)
        let timed = Fixture.milestone(target: target, timed: true)
        let dates = RefreshSchedule.dates(for: [timed], from: now, days: 5, calendar: Fixture.calendar)
        #expect(dates == [
            Fixture.date(2026, 11, 17),
            Fixture.date(2026, 11, 17, 9, 30), // one day to go: the final day begins
            Fixture.date(2026, 11, 18),
            target,
            target.addingTimeInterval(60), // Now ends
            Fixture.date(2026, 11, 19),
            Fixture.date(2026, 11, 19, 9, 30), // first day past ends
            Fixture.date(2026, 11, 20),
            Fixture.date(2026, 11, 20, 9, 30),
            Fixture.date(2026, 11, 21),
        ])
    }

    /// @spec COUNT-SCHED-002
    @Test("Day marks are included for a timed target beyond the window and for one already past")
    func outsideWindow() {
        let future = Fixture.milestone(target: Fixture.date(2026, 12, 25, 18, 0), timed: true)
        let past = Fixture.milestone(target: Fixture.date(2026, 11, 10, 7, 15), timed: true)
        let dates = RefreshSchedule.dates(for: [future, past], from: now, days: 1, calendar: Fixture.calendar)
        #expect(dates == [Fixture.date(2026, 11, 16, 18, 0), Fixture.date(2026, 11, 17)])
        let nextMorning = RefreshSchedule.dates(
            for: [past], from: Fixture.date(2026, 11, 17, 1), days: 1, calendar: Fixture.calendar
        )
        #expect(nextMorning == [Fixture.date(2026, 11, 17, 7, 15), Fixture.date(2026, 11, 18)])
    }

    /// @spec COUNT-SCHED-003
    @Test("Nothing at or before now is scheduled, and shared instants appear once")
    func sortedAndUnique() {
        let first = Fixture.milestone(target: Fixture.date(2026, 11, 17, 0, 0), timed: true)
        let second = Fixture.milestone(target: Fixture.date(2026, 11, 17, 0, 0), timed: true)
        let dates = RefreshSchedule.dates(for: [first, second], from: now, days: 1, calendar: Fixture.calendar)
        #expect(dates == dates.sorted())
        #expect(Set(dates).count == dates.count)
        #expect(dates.allSatisfy { $0 > now })
    }
}
