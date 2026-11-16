import Foundation
import SwiftData

/// The persisted form of a `Milestone`. Only the store layer and the app's
/// editing code touch this; everything else uses the `Milestone` snapshot.
@Model
public final class MilestoneRecord {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var targetDate: Date
    public var includesTime: Bool
    public var startDate: Date?
    public var symbol: String
    public var themeID: String
    public var sortOrder: Int
    public var isArchived: Bool
    public var createdAt: Date

    public init(_ milestone: Milestone) {
        id = milestone.id
        title = milestone.title
        targetDate = milestone.targetDate
        includesTime = milestone.includesTime
        startDate = milestone.startDate
        symbol = milestone.symbol
        themeID = milestone.themeID
        sortOrder = milestone.sortOrder
        isArchived = milestone.isArchived
        createdAt = milestone.createdAt
    }

    /// Copies every editable field from a snapshot. `id` and `createdAt` are identity and stay put.
    public func apply(_ milestone: Milestone) {
        title = milestone.title
        targetDate = milestone.targetDate
        includesTime = milestone.includesTime
        startDate = milestone.startDate
        symbol = milestone.symbol
        themeID = milestone.themeID
        sortOrder = milestone.sortOrder
        isArchived = milestone.isArchived
    }

    public var snapshot: Milestone {
        Milestone(
            id: id,
            title: title,
            targetDate: targetDate,
            includesTime: includesTime,
            startDate: startDate,
            symbol: symbol,
            themeID: themeID,
            sortOrder: sortOrder,
            isArchived: isArchived,
            createdAt: createdAt
        )
    }
}
