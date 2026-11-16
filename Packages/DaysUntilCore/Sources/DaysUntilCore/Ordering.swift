import Foundation

public extension Sequence<Milestone> {
    /// Display order: upcoming milestones soonest first, then past ones most
    /// recent first. An all-day milestone sits at the start of its day.
    /// Milestones at the same position fall back to title so the order is stable.
    /// @spec COUNT-ORDER-001, COUNT-ORDER-002
    func sortedForDisplay(now: Date = .now, calendar: Calendar = .current) -> [Milestone] {
        let placed = map { milestone in
            (
                milestone: milestone,
                isPast: milestone.countdown(now: now, calendar: calendar).phase == .past,
                position: milestone.targetPosition(in: calendar)
            )
        }
        let sorted = placed.sorted { lhs, rhs in
            if lhs.isPast != rhs.isPast {
                return !lhs.isPast
            }
            if lhs.position != rhs.position {
                return lhs.isPast ? lhs.position > rhs.position : lhs.position < rhs.position
            }
            let titles = lhs.milestone.title.localizedStandardCompare(rhs.milestone.title)
            if titles != .orderedSame {
                return titles == .orderedAscending
            }
            return lhs.milestone.id.uuidString < rhs.milestone.id.uuidString
        }
        return sorted.map(\.milestone)
    }

    /// The first milestone in display order: what a widget shows when no
    /// particular milestone has been chosen for it.
    /// @spec COUNT-ORDER-003
    func nextMilestone(now: Date = .now, calendar: Calendar = .current) -> Milestone? {
        sortedForDisplay(now: now, calendar: calendar).first
    }
}

public extension Milestone {
    /// One spoken line for a face: "Lisbon trip, 23 days until, 63% complete".
    /// @spec FACE-A11Y-001
    func accessibilityLabel(now: Date = .now, calendar: Calendar = .current) -> String {
        let countdown = countdown(now: now, calendar: calendar)
        let parts = [title, countdown.text.sentence, countdown.percentText.map { "\($0) complete" }]
        return parts.compactMap(\.self).joined(separator: ", ")
    }
}

/// When widget timelines need a fresh entry.
public enum RefreshSchedule {
    /// The moments, after `now`, at which any of the milestones' displays
    /// change, up to the last of the next `days` midnights: each of those
    /// midnights and, for every timed milestone, each whole number of days
    /// before or after its target, the target itself, and the end of `Now`.
    /// Sorted, without duplicates.
    /// @spec COUNT-SCHED-001, COUNT-SCHED-002, COUNT-SCHED-003
    public static func dates(
        for milestones: [Milestone],
        from now: Date = .now,
        days: Int = 5,
        calendar: Calendar = .current
    ) -> [Date] {
        let window = max(days, 1)
        let today = calendar.startOfDay(for: now)
        let midnights = (1 ... window).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        guard let horizon = midnights.last else { return [] }
        let timed = milestones.filter(\.includesTime).flatMap { milestone in
            instants(for: milestone.targetDate, from: now, window: window, calendar: calendar)
        }
        return Set(midnights + timed).filter { $0 > now && $0 <= horizon }.sorted()
    }

    /// Candidate instants for one timed target; the caller trims to the window.
    private static func instants(for target: Date, from now: Date, window: Int, calendar: Calendar) -> [Date] {
        let offset = calendar.dateComponents([.day], from: target, to: now).day ?? 0
        let dayMarks = (offset - 1 ... offset + window + 1).compactMap {
            calendar.date(byAdding: .day, value: $0, to: target)
        }
        return dayMarks + [target, target.addingTimeInterval(TimedDistance.nowWindow)]
    }
}
