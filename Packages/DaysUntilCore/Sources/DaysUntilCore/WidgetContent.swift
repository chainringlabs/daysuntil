import Foundation

/// What a Milestone widget shows.
public enum WidgetContent: Hashable, Sendable {
    case milestone(Milestone)
    /// There are no active milestones to show.
    case noMilestones
    /// The chosen milestone was deleted or archived.
    case removed
    /// The store could not be opened or read.
    case unavailable

    /// Decides what a Milestone widget shows at one moment.
    ///
    /// A chosen milestone is shown or reported removed, never replaced by
    /// another. With none chosen the widget follows the next milestone.
    ///
    /// - Parameter milestones: every stored milestone, archived included, or
    ///   `nil` when the store is unreadable.
    /// @spec WIDGET-SHOW-001, WIDGET-SHOW-002, WIDGET-SHOW-003, WIDGET-SHOW-004, WIDGET-SHOW-005
    public static func resolve(
        milestones: [Milestone]?,
        chosenID: UUID?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> WidgetContent {
        guard let milestones else { return .unavailable }
        let active = milestones.filter { !$0.isArchived }
        if let chosenID {
            return active.first { $0.id == chosenID }.map(WidgetContent.milestone) ?? .removed
        }
        return active.nextMilestone(now: now, calendar: calendar).map(WidgetContent.milestone) ?? .noMilestones
    }

    /// True when the widget shows a message instead of a milestone.
    public var isMessage: Bool {
        if case .milestone = self {
            return false
        }
        return true
    }
}

/// What the Upcoming widget shows.
public enum UpcomingContent: Hashable, Sendable {
    case rows([Milestone])
    case noMilestones
    case unavailable

    /// How many rows fit at a size.
    public static func rowLimit(for size: FaceSize) -> Int {
        size == .large ? 7 : 3
    }

    /// - Parameter milestones: every stored milestone, archived included, or
    ///   `nil` when the store is unreadable.
    /// @spec WIDGET-LIST-001, WIDGET-LIST-005
    public static func resolve(
        milestones: [Milestone]?,
        size: FaceSize,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> UpcomingContent {
        guard let milestones else { return .unavailable }
        let rows = milestones
            .filter { !$0.isArchived }
            .sortedForDisplay(now: now, calendar: calendar)
            .prefix(rowLimit(for: size))
        return rows.isEmpty ? .noMilestones : .rows(Array(rows))
    }

    public var isMessage: Bool {
        if case .rows = self {
            return false
        }
        return true
    }
}

/// One entry in the Milestone widget's milestone picker.
public struct MilestoneChoice: Hashable, Sendable {
    /// The title standing in for a milestone that no longer exists.
    public static let removedTitle = "Removed milestone"

    public let id: UUID
    public let title: String

    public init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }

    /// Answers for every id asked about, in order. An id with no milestone
    /// gets a stand-in, so a widget keeps the choice and can say it was
    /// removed instead of being handed a different milestone.
    /// @spec WIDGET-CONFIG-003
    public static func resolve(ids: [UUID], in milestones: [Milestone]) -> [MilestoneChoice] {
        ids.map { id in
            let title = milestones.first { $0.id == id }?.title
            return MilestoneChoice(id: id, title: title ?? removedTitle)
        }
    }
}
