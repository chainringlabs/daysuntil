import Foundation

/// Where a milestone stands relative to a given moment: how far away it is,
/// in which direction, and how much of its span has elapsed.
public struct Countdown: Hashable, Sendable {
    public enum Phase: Sendable {
        /// The target is still ahead: "days until".
        case upcoming
        /// The target is today (all-day) or this very minute (timed).
        case today
        /// The target has passed: "days since".
        case past
    }

    public let phase: Phase
    /// Whole days between now and the target, always non-negative.
    public let days: Int
    /// Hour and minute remainder beyond `days`. Zero for all-day milestones.
    public let hours: Int
    public let minutes: Int
    public let isTimed: Bool
    /// Fraction of the start-to-target span that has elapsed, 0...1.
    /// `nil` when the milestone has no span (start is not before the target).
    public let progress: Double?
    /// Length of the span in days (at least 1) when `progress` exists.
    public let totalDays: Int?
    /// Days of the span already elapsed, 0...totalDays.
    public let elapsedDays: Int?

    /// @spec COUNT-ALLDAY-001, COUNT-ALLDAY-002, COUNT-ALLDAY-003, COUNT-TIMED-001, COUNT-TIMED-002
    /// @spec COUNT-PROG-001, COUNT-PROG-002, COUNT-PROG-003, COUNT-PROG-004, COUNT-PROG-005
    public init(for milestone: Milestone, now: Date = .now, calendar: Calendar = .current) {
        isTimed = milestone.includesTime
        let target = milestone.targetPosition(in: calendar)
        let start = milestone.progressStart(in: calendar)
        let span: Span?
        if milestone.includesTime {
            let distance = TimedDistance(to: target, now: now, calendar: calendar)
            (phase, days) = (distance.phase, distance.days)
            (hours, minutes) = (distance.hours, distance.minutes)
            span = Span(timedFrom: start, to: target, now: now)
        } else {
            let offset = calendar.daysBetween(now, target)
            phase = offset > 0 ? .upcoming : (offset == 0 ? .today : .past)
            days = abs(offset)
            hours = 0
            minutes = 0
            span = Span(allDayFrom: start, to: target, now: now, calendar: calendar)
        }
        progress = span?.progress
        totalDays = span?.totalDays
        elapsedDays = span?.elapsedDays
    }

    /// True when a timed milestone is under a day away.
    /// @spec COUNT-TIMED-003
    public var isFinalDay: Bool {
        isTimed && phase == .upcoming && days == 0
    }

    /// True when a timed milestone passed under a day ago and `Now` is over.
    /// @spec COUNT-TIMED-004
    public var isFirstDayPast: Bool {
        isTimed && phase == .past && days == 0
    }

    /// True when a display should run a clock instead of showing a day count.
    /// @spec COUNT-TIMED-005
    public var needsLiveClock: Bool {
        isFinalDay || isFirstDayPast
    }
}

/// How far a timed target is from now, split into days, hours and minutes.
struct TimedDistance {
    let phase: Countdown.Phase
    let days: Int
    let hours: Int
    let minutes: Int

    /// How long `Now` lasts after the target instant.
    static let nowWindow: TimeInterval = 60

    init(to target: Date, now: Date, calendar: Calendar) {
        let sinceTarget = now.timeIntervalSince(target)
        guard sinceTarget < 0 || sinceTarget >= Self.nowWindow else {
            (phase, days, hours, minutes) = (.today, 0, 0, 0)
            return
        }
        let parts = calendar.dateComponents([.day, .hour, .minute], from: min(now, target), to: max(now, target))
        phase = sinceTarget < 0 ? .upcoming : .past
        days = parts.day ?? 0
        hours = parts.hour ?? 0
        minutes = parts.minute ?? 0
    }
}

/// The start-to-target span of a milestone and how much of it has elapsed.
private struct Span {
    let progress: Double
    let totalDays: Int
    let elapsedDays: Int

    /// All-day spans are measured in whole calendar days.
    init?(allDayFrom start: Date, to target: Date, now: Date, calendar: Calendar) {
        let total = calendar.daysBetween(start, target)
        guard total > 0 else { return nil }
        totalDays = total
        elapsedDays = min(max(calendar.daysBetween(start, now), 0), total)
        progress = Double(elapsedDays) / Double(total)
    }

    /// Timed spans are measured in seconds, then expressed in days for the dot grid.
    init?(timedFrom start: Date, to target: Date, now: Date) {
        let total = target.timeIntervalSince(start)
        guard total > 0 else { return nil }
        progress = min(max(now.timeIntervalSince(start) / total, 0), 1)
        totalDays = max(1, Int((total / 86400).rounded(.up)))
        elapsedDays = min(Int(progress * Double(totalDays)), totalDays)
    }
}

public extension Milestone {
    func countdown(now: Date = .now, calendar: Calendar = .current) -> Countdown {
        Countdown(for: self, now: now, calendar: calendar)
    }
}

extension Calendar {
    /// Calendar days from `start` to `end`, ignoring time of day. Negative when
    /// `end` is earlier. Counting from start-of-day keeps DST shifts from
    /// producing off-by-one results.
    func daysBetween(_ start: Date, _ end: Date) -> Int {
        dateComponents([.day], from: startOfDay(for: start), to: startOfDay(for: end)).day ?? 0
    }
}
