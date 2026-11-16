import Foundation

/// A span of days laid out as dots. Long spans are bucketed into weeks, months
/// or years so the grid never exceeds what a widget can show.
public struct DotGrid: Hashable, Sendable {
    public enum Unit: Int, CaseIterable, Sendable {
        case day = 1
        case week = 7
        case month = 30
        case year = 365

        public var name: String {
            switch self {
            case .day: "day"
            case .week: "week"
            case .month: "month"
            case .year: "year"
            }
        }
    }

    public let count: Int
    public let filled: Int
    public let unit: Unit

    public init(totalDays: Int, elapsedDays: Int, maxDots: Int) {
        let total = max(totalDays, 1)
        let elapsed = min(max(elapsedDays, 0), total)
        let limit = max(maxDots, 1)
        let fitting = Unit.allCases.first { Self.buckets(total, in: $0) <= limit } ?? .year
        unit = fitting
        count = min(Self.buckets(total, in: fitting), limit)
        // A finished span fills every dot even when the last bucket is partial.
        filled = elapsed == total ? count : min(elapsed / fitting.rawValue, count)
    }

    /// "1 dot = 1 week"; `nil` when each dot is a single day.
    public var legend: String? {
        unit == .day ? nil : "1 dot = 1 \(unit.name)"
    }

    private static func buckets(_ days: Int, in unit: Unit) -> Int {
        (days + unit.rawValue - 1) / unit.rawValue
    }
}

public extension Countdown {
    /// The dot grid for this countdown's span, or `nil` when it has no span.
    func dotGrid(maxDots: Int) -> DotGrid? {
        guard let totalDays, let elapsedDays else { return nil }
        return DotGrid(totalDays: totalDays, elapsedDays: elapsedDays, maxDots: maxDots)
    }
}
