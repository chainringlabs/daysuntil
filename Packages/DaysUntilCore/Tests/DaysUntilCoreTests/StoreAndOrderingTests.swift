@testable import DaysUntilCore
import Foundation
import SwiftData
import Testing

@Suite("Ordering and refresh")
struct OrderingTests {
    @Test("Upcoming soonest first, then past most recent first")
    func displayOrder() {
        let now = Fixture.date(2026, 11, 16)
        let far = Milestone(title: "Far", targetDate: Fixture.date(2027, 6, 1))
        let near = Milestone(title: "Near", targetDate: Fixture.date(2026, 11, 20))
        let old = Milestone(title: "Old", targetDate: Fixture.date(2020, 1, 1))
        let recent = Milestone(title: "Recent", targetDate: Fixture.date(2026, 11, 1))
        let sorted = [old, far, recent, near].sortedForDisplay(now: now)
        #expect(sorted.map(\.title) == ["Near", "Far", "Recent", "Old"])
    }

    @Test("Refresh dates are the coming midnights plus timed targets")
    func refreshDates() {
        let now = Fixture.date(2026, 11, 16, 14)
        let timed = Fixture.milestone(target: Fixture.date(2026, 11, 17, 9, 30), timed: true)
        let allDay = Fixture.milestone(target: Fixture.date(2026, 11, 17))
        let dates = RefreshSchedule.dates(for: [timed, allDay], from: now, days: 2, calendar: Fixture.calendar)
        #expect(dates == [
            Fixture.date(2026, 11, 17),
            Fixture.date(2026, 11, 17, 9, 30),
            Fixture.date(2026, 11, 18),
        ])
    }
}

@Suite("Milestone")
struct MilestoneTests {
    @Test("Deep links round-trip the id")
    func deepLink() throws {
        let milestone = Fixture.milestone(target: .now)
        #expect(Milestone.id(from: milestone.url) == milestone.id)
        #expect(try Milestone.id(from: #require(URL(string: "https://example.com/milestone/x"))) == nil)
    }

    @Test("Emoji symbols are told apart from SF Symbol names")
    func emoji() {
        var milestone = Fixture.milestone(target: .now)
        milestone.symbol = "🎂"
        #expect(milestone.symbolIsEmoji)
        milestone.symbol = "figure.run"
        #expect(!milestone.symbolIsEmoji)
    }

    @Test("Unknown theme ids fall back to the default")
    func themeFallback() {
        #expect(Theme.named("nope") == Theme.default)
    }

    @Test("Every theme keeps text and accent readable on its background", arguments: Theme.all)
    func themeContrast(theme: Theme) {
        for background in [theme.backgroundTop, theme.backgroundBottom] {
            #expect(theme.ink.contrast(with: background) >= 4.5, "\(theme.name) ink")
            #expect(theme.accent.contrast(with: background) >= 3, "\(theme.name) accent")
        }
    }
}

@Suite("Store")
struct StoreTests {
    @Test("Records round-trip through SwiftData and skip archived by default")
    func roundTrip() throws {
        let container = try MilestoneStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let active = Fixture.milestone(target: Fixture.date(2027, 1, 1), start: Fixture.date(2026, 1, 1))
        var archived = Fixture.milestone(target: Fixture.date(2027, 2, 1))
        archived.isArchived = true
        context.insert(MilestoneRecord(active))
        context.insert(MilestoneRecord(archived))
        try context.save()

        #expect(try MilestoneStore.milestones(in: container) == [active])
        #expect(try MilestoneStore.milestones(in: container, includeArchived: true).count == 2)
        #expect(try MilestoneStore.milestone(id: archived.id, in: container) == archived)
        #expect(try MilestoneStore.milestone(id: UUID(), in: container) == nil)
    }

    @Test("Applying a snapshot updates fields but keeps identity")
    func apply() {
        let original = Fixture.milestone(target: Fixture.date(2027, 1, 1))
        let record = MilestoneRecord(original)
        var edited = original
        edited.title = "Renamed"
        edited.themeID = "moss"
        edited.createdAt = .distantFuture
        record.apply(edited)
        #expect(record.title == "Renamed")
        #expect(record.themeID == "moss")
        #expect(record.createdAt == original.createdAt)
    }
}
