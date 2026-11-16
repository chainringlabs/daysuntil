import Foundation

/// A plain value describing one milestone. Views and date math work on this,
/// never on the SwiftData record, so they stay testable and `Sendable`.
public struct Milestone: Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    /// The moment being counted to (future) or from (past).
    public var targetDate: Date
    /// `false` counts whole calendar days; `true` counts to the minute.
    public var includesTime: Bool
    /// Optional explicit start for progress. Falls back to `createdAt`.
    public var startDate: Date?
    /// An SF Symbol name or a single emoji.
    public var symbol: String
    public var themeID: String
    public var sortOrder: Int
    public var isArchived: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        targetDate: Date,
        includesTime: Bool = false,
        startDate: Date? = nil,
        symbol: String = "flag.fill",
        themeID: String = Theme.default.id,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.includesTime = includesTime
        self.startDate = startDate
        self.symbol = symbol
        self.themeID = themeID
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = createdAt
    }

    public var theme: Theme {
        Theme.named(themeID)
    }

    /// True when `symbol` should be drawn as text (an emoji) rather than an SF Symbol.
    public var symbolIsEmoji: Bool {
        !symbol.allSatisfy(\.isASCII)
    }

    /// Deep link that opens the app on this milestone.
    public var url: URL {
        URL(string: "daysuntil://milestone/\(id.uuidString)") ?? URL(filePath: "/")
    }

    /// Parses a deep link produced by `url`.
    public static func id(from url: URL) -> UUID? {
        guard url.scheme == "daysuntil", url.host() == "milestone" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}
