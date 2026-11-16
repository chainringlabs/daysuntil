@testable import DaysUntilCore
import Foundation
import SwiftData
import Testing

@Suite("Store")
struct StoreTests {
    private let now = Fixture.date(2026, 11, 16)

    /// @spec STORE-001, STORE-003, STORE-005, STORE-006
    @Test("Records round-trip, archived ones are skipped by default, and lookups by id ignore archiving")
    func roundTrip() throws {
        let container = try MilestoneStore.makeContainer(inMemory: true)
        let inMemory = container.configurations.map(\.isStoredInMemoryOnly)
        #expect(inMemory == [true])
        let context = ModelContext(container)
        let active = Fixture.milestone(target: Fixture.day(2027, 1, 1), start: Fixture.day(2026, 1, 1))
        var archived = Fixture.milestone(target: Fixture.day(2027, 2, 1))
        archived.isArchived = true
        context.insert(MilestoneRecord(active))
        context.insert(MilestoneRecord(archived))
        try context.save()

        #expect(try MilestoneStore.milestones(in: container, now: now) == [active])
        #expect(try MilestoneStore.milestones(in: container, includeArchived: true, now: now).count == 2)
        #expect(try MilestoneStore.milestone(id: archived.id, in: container) == archived)
        #expect(try MilestoneStore.milestone(id: UUID(), in: container) == nil)
    }

    /// @spec STORE-002
    @Test("Applying a value updates fields but keeps id and the added date")
    func apply() {
        let original = Fixture.milestone(target: Fixture.day(2027, 1, 1))
        let record = MilestoneRecord(original)
        var edited = original
        edited.id = UUID()
        edited.title = "Renamed"
        edited.themeID = "moss"
        edited.createdAt = .distantFuture
        record.apply(edited)
        #expect(record.title == "Renamed")
        #expect(record.themeID == "moss")
        #expect(record.id == original.id)
        #expect(record.createdAt == original.createdAt)
    }

    /// @spec STORE-004
    @Test("Milestones are read in display order")
    func order() throws {
        let container = try MilestoneStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let titles = [
            "Past": Fixture.day(2026, 11, 1),
            "Far": Fixture.day(2027, 6, 1),
            "Near": Fixture.day(2026, 11, 20),
        ]
        for (title, target) in titles {
            context.insert(MilestoneRecord(Fixture.milestone(title: title, target: target)))
        }
        try context.save()
        #expect(try MilestoneStore.milestones(in: container, now: now).map(\.title) == ["Near", "Far", "Past"])
    }

    /// @spec STORE-007
    @Test("Without an App Group identifier the store lives under Application Support")
    func fallbackLocation() {
        // The test runner's bundle has no AppGroupIdentifier key.
        #expect(Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") == nil)
        let url = MilestoneStore.storeURL
        #expect(url.path().hasPrefix(URL.applicationSupportDirectory.path()))
        #expect(url.path().hasSuffix("DaysUntil/Milestones.store"))
    }
}
