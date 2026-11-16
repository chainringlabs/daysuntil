import Foundation

/// The words a countdown is displayed with. English only for now.
public struct CountdownText: Hashable, Sendable {
    /// The hero value: "42", "Today", "5h 12m".
    public let value: String
    /// What the value means: "days until", "day since", "left".
    public let label: String

    /// @spec COUNT-TEXT-001, COUNT-TEXT-002, COUNT-TEXT-003, COUNT-TEXT-004, COUNT-TEXT-005, COUNT-TEXT-006
    public init(_ countdown: Countdown) {
        switch countdown.phase {
        case .today:
            value = countdown.isTimed ? "Now" : "Today"
            label = "it's here"
        case .upcoming where countdown.isFinalDay:
            value = Self.clock(hours: countdown.hours, minutes: countdown.minutes)
            label = "left"
        case .past where countdown.isFirstDayPast:
            value = Self.clock(hours: countdown.hours, minutes: countdown.minutes)
            label = "ago"
        case .upcoming:
            value = countdown.days.formatted()
            label = "\(Self.dayWord(countdown.days)) until"
        case .past:
            value = countdown.days.formatted()
            label = "\(Self.dayWord(countdown.days)) since"
        }
    }

    /// A one-line reading for accessibility and compact rows: "42 days until".
    public var sentence: String {
        "\(value) \(label)"
    }

    private static func dayWord(_ days: Int) -> String {
        days == 1 ? "day" : "days"
    }

    private static func clock(hours: Int, minutes: Int) -> String {
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return minutes > 0 ? "\(minutes)m" : "<1m"
    }
}

public extension Countdown {
    var text: CountdownText {
        CountdownText(self)
    }

    /// @spec COUNT-TEXT-007
    /// Progress as a whole percentage, "64%".
    var percentText: String? {
        progress.map { "\(Int(($0 * 100).rounded(.down)))%" }
    }

    /// @spec COUNT-TEXT-008
    /// The day count restated in weeks, e.g. "6 weeks, 2 days". `nil` under a week.
    var weeksText: String? {
        guard days >= 7 else { return nil }
        let weeks = days / 7
        let rest = days % 7
        let weekPart = "\(weeks) \(weeks == 1 ? "week" : "weeks")"
        return rest == 0 ? weekPart : "\(weekPart), \(rest) \(rest == 1 ? "day" : "days")"
    }
}
