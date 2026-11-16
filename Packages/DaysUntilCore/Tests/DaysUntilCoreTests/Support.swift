@testable import DaysUntilCore
import Foundation

/// A fixed calendar and date builder so tests do not depend on the machine's
/// locale or time zone. New York is used because it observes DST.
enum Fixture {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: parts) ?? .distantPast
    }

    static func milestone(
        target: Date,
        timed: Bool = false,
        start: Date? = nil,
        created: Date = date(2026, 1, 1)
    ) -> Milestone {
        Milestone(title: "Test", targetDate: target, includesTime: timed, startDate: start, createdAt: created)
    }

    static func countdown(_ milestone: Milestone, now: Date) -> Countdown {
        Countdown(for: milestone, now: now, calendar: calendar)
    }
}
