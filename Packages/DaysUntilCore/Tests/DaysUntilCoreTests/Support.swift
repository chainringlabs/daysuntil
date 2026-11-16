@testable import DaysUntilCore
import Foundation

/// Fixed calendars and date builders so tests do not depend on the machine's
/// locale or time zone. New York is the default because it observes DST.
enum Fixture {
    static let calendar = calendar(in: "America/New_York")
    static let losAngeles = calendar(in: "America/Los_Angeles")
    static let tokyo = calendar(in: "Asia/Tokyo")
    static let utc = calendar(in: "UTC")

    static func calendar(in zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? .gmt
        return calendar
    }

    /// An instant given as wall-clock time in a calendar (New York unless stated).
    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        in calendar: Calendar = calendar
    ) -> Date {
        let parts = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: parts) ?? .distantPast
    }

    /// A calendar day as it is stored: 00:00 UTC of that day. Built here
    /// independently of `CalendarDay` so tests do not rely on the code under test.
    static func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        date(year, month, day, in: utc)
    }

    static func milestone(
        title: String = "Test",
        target: Date,
        timed: Bool = false,
        start: Date? = nil,
        created: Date = date(2026, 1, 1)
    ) -> Milestone {
        Milestone(title: title, targetDate: target, includesTime: timed, startDate: start, createdAt: created)
    }

    static func countdown(_ milestone: Milestone, now: Date, calendar: Calendar = calendar) -> Countdown {
        Countdown(for: milestone, now: now, calendar: calendar)
    }
}
