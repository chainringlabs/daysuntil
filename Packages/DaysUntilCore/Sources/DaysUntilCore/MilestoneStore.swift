import Foundation
import SwiftData

/// Opens the SwiftData store shared by the app and the widget extension, and
/// reads milestones out of it as snapshots.
public enum MilestoneStore {
    /// Info.plist key both targets set to the App Group identifier.
    static let appGroupKey = "AppGroupIdentifier"

    /// The store location. Inside the App Group container when the process has
    /// one, so the widget sees the app's data; otherwise Application Support,
    /// which keeps unsigned and test builds working.
    public static var storeURL: URL {
        let group = Bundle.main.object(forInfoDictionaryKey: appGroupKey) as? String
        let container = group.flatMap {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0)
        }
        let directory = (container ?? URL.applicationSupportDirectory)
            .appending(path: "DaysUntil", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "Milestones.store")
    }

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([MilestoneRecord.self])
        let configuration = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// All milestones, in display order. Archived ones are left out unless asked for.
    public static func milestones(
        in container: ModelContainer,
        includeArchived: Bool = false,
        now: Date = .now
    ) throws -> [Milestone] {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<MilestoneRecord>())
        return records
            .map(\.snapshot)
            .filter { includeArchived || !$0.isArchived }
            .sortedForDisplay(now: now)
    }

    public static func milestone(id: UUID, in container: ModelContainer) throws -> Milestone? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<MilestoneRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.snapshot
    }
}
