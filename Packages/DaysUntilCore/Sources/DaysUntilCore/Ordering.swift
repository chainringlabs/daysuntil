import Foundation

public extension Sequence<Milestone> {
    /// Display order: upcoming milestones soonest first, then past ones most
    /// recent first. Ties fall back to title so the order is stable.
    func sortedForDisplay(now: Date = .now) -> [Milestone] {
        sorted { lhs, rhs in
            let lhsPast = lhs.isPast(at: now)
            let rhsPast = rhs.isPast(at: now)
            if lhsPast != rhsPast {
                return !lhsPast
            }
            if lhs.targetDate != rhs.targetDate {
                return lhsPast ? lhs.targetDate > rhs.targetDate : lhs.targetDate < rhs.targetDate
            }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }
}

extension Milestone {
    func isPast(at now: Date, calendar: Calendar = .current) -> Bool {
        countdown(now: now, calendar: calendar).phase == .past
    }
}

/// When widget timelines need a fresh entry.
public enum RefreshSchedule {
    /// The moments, after `now`, at which any of the milestones' displays
    /// change: each of the next `days` midnights, plus the target instant of
    /// any timed milestone inside that window. Sorted, without duplicates.
    public static func dates(
        for milestones: [Milestone],
        from now: Date = .now,
        days: Int = 5,
        calendar: Calendar = .current
    ) -> [Date] {
        let today = calendar.startOfDay(for: now)
        let midnights = (1 ... max(days, 1)).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        guard let horizon = midnights.last else { return [] }
        let targets = milestones
            .filter { $0.includesTime && $0.targetDate > now && $0.targetDate < horizon }
            .map(\.targetDate)
        return Set(midnights + targets).sorted()
    }
}
