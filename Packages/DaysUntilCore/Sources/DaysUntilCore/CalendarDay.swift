import Foundation

/// A day on the calendar, independent of time zone: 9 December is 9 December
/// everywhere. All-day milestones are on calendar days, not instants.
///
/// A calendar day is carried in a `Date` field as 00:00 UTC of that day and
/// read back by its UTC year, month and day only.
/// @spec COUNT-DAY-001, COUNT-DAY-002, COUNT-DAY-003
public struct CalendarDay: Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day carried by a stored `Date`: its UTC year, month and day,
    /// whatever its time of day.
    public init(storedInstant: Date) {
        self.init(containing: storedInstant, in: Self.utc)
    }

    /// The day an instant falls on in a calendar's time zone.
    public init(containing instant: Date, in calendar: Calendar) {
        let parts = Self.gregorian(in: calendar.timeZone).dateComponents([.year, .month, .day], from: instant)
        self.init(year: parts.year ?? 1, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// The `Date` this day is stored as: 00:00 UTC.
    public var storedInstant: Date {
        Self.utc.date(from: components) ?? .distantPast
    }

    /// The start of this day in a calendar's time zone.
    public func start(in calendar: Calendar) -> Date {
        let local = Self.gregorian(in: calendar.timeZone)
        return local.date(from: components).map(local.startOfDay(for:)) ?? storedInstant
    }

    /// The day `days` after this one (before, when negative).
    public func adding(days: Int) -> CalendarDay {
        let moved = Self.utc.date(byAdding: .day, value: days, to: storedInstant) ?? storedInstant
        return CalendarDay(storedInstant: moved)
    }

    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private var components: DateComponents {
        DateComponents(year: year, month: month, day: day)
    }

    private static let utc = gregorian(in: .gmt)

    /// Year, month and day are always Gregorian, so a day means the same
    /// thing whatever calendar system the Mac is set to.
    private static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}

public extension Milestone {
    /// The same milestone as a timed one: each date keeps its calendar day and
    /// gains the given time of day. Unchanged when already timed.
    /// @spec COUNT-DAY-004
    func convertedToTimed(hour: Int, minute: Int, calendar: Calendar = .current) -> Milestone {
        guard !includesTime else { return self }
        func timed(_ stored: Date) -> Date {
            let start = CalendarDay(storedInstant: stored).start(in: calendar)
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start) ?? start
        }
        var copy = self
        copy.includesTime = true
        copy.targetDate = timed(targetDate)
        copy.startDate = startDate.map(timed)
        return copy
    }

    /// The same milestone as an all-day one: each date becomes the calendar
    /// day it falls on. Unchanged when already all-day.
    /// @spec COUNT-DAY-005
    func convertedToAllDay(calendar: Calendar = .current) -> Milestone {
        guard includesTime else { return self }
        func day(_ instant: Date) -> Date {
            CalendarDay(containing: instant, in: calendar).storedInstant
        }
        var copy = self
        copy.includesTime = false
        copy.targetDate = day(targetDate)
        copy.startDate = startDate.map(day)
        return copy
    }
}

public extension Milestone {
    /// One of this milestone's stored dates as a local instant, for display
    /// and date pickers: the start of its calendar day for an all-day
    /// milestone, the instant itself for a timed one.
    func localDate(for stored: Date, calendar: Calendar = .current) -> Date {
        includesTime ? stored : CalendarDay(storedInstant: stored).start(in: calendar)
    }

    /// The reverse of `localDate(for:calendar:)`: what to store for a date
    /// picked in the local calendar.
    func storedDate(forLocal local: Date, calendar: Calendar = .current) -> Date {
        includesTime ? local : CalendarDay(containing: local, in: calendar).storedInstant
    }
}

extension Milestone {
    /// Where the target sits on the timeline: the start of its calendar day
    /// for an all-day milestone, the target instant for a timed one.
    func targetPosition(in calendar: Calendar) -> Date {
        localDate(for: targetDate, calendar: calendar)
    }

    /// Where progress is measured from: the start date when set, otherwise
    /// the instant the milestone was added.
    func progressStart(in calendar: Calendar) -> Date {
        startDate.map { localDate(for: $0, calendar: calendar) } ?? createdAt
    }
}
