@testable import DaysUntilCore
import Foundation
import Testing

@Suite("What a Milestone widget shows")
struct WidgetContentTests {
    private let now = Fixture.date(2026, 11, 16, 10)
    private let near = Fixture.milestone(title: "Near", target: Fixture.day(2026, 11, 20))
    private let far = Fixture.milestone(title: "Far", target: Fixture.day(2027, 6, 1))

    private func resolve(_ milestones: [Milestone]?, chosen: UUID?, at date: Date? = nil) -> WidgetContent {
        WidgetContent.resolve(milestones: milestones, chosenID: chosen, now: date ?? now, calendar: Fixture.calendar)
    }

    /// @spec WIDGET-SHOW-001
    @Test("An unreadable store is reported as such, chosen or not")
    func unavailable() {
        #expect(resolve(nil, chosen: nil) == .unavailable)
        #expect(resolve(nil, chosen: near.id) == .unavailable)
        #expect(WidgetContent.unavailable.isMessage)
    }

    /// @spec WIDGET-SHOW-002
    @Test("A chosen milestone that exists is shown, even when another is sooner")
    func chosen() {
        #expect(resolve([near, far], chosen: far.id) == .milestone(far))
        #expect(!WidgetContent.milestone(far).isMessage)
    }

    /// @spec WIDGET-SHOW-003
    @Test("A chosen milestone that was deleted or archived is reported removed, never replaced")
    func removed() {
        var archived = far
        archived.isArchived = true
        #expect(resolve([near], chosen: far.id) == .removed)
        #expect(resolve([near, archived], chosen: far.id) == .removed)
        #expect(resolve([], chosen: far.id) == .removed)
        #expect(WidgetContent.removed.isMessage)
    }

    /// @spec WIDGET-SHOW-004
    @Test("With none chosen, the widget follows the next milestone at the moment drawn")
    func follows() {
        var archivedSooner = Fixture.milestone(title: "Hidden", target: Fixture.day(2026, 11, 17))
        archivedSooner.isArchived = true
        let all = [far, near, archivedSooner]
        #expect(resolve(all, chosen: nil) == .milestone(near))
        #expect(resolve(all, chosen: nil, at: Fixture.date(2026, 11, 21, 10)) == .milestone(far))
    }

    /// @spec WIDGET-SHOW-005
    @Test("With none chosen and nothing active, the widget asks for a milestone")
    func empty() {
        var archived = near
        archived.isArchived = true
        #expect(resolve([], chosen: nil) == .noMilestones)
        #expect(resolve([archived], chosen: nil) == .noMilestones)
        #expect(WidgetContent.noMilestones.isMessage)
    }

    /// @spec WIDGET-CONFIG-003
    @Test("Every id asked about gets an answer: the milestone's title, or a stand-in")
    func choices() {
        let gone = UUID()
        let choices = MilestoneChoice.resolve(ids: [far.id, gone, near.id], in: [near, far])
        #expect(choices == [
            MilestoneChoice(id: far.id, title: "Far"),
            MilestoneChoice(id: gone, title: "Removed milestone"),
            MilestoneChoice(id: near.id, title: "Near"),
        ])
    }
}

@Suite("What the Upcoming widget shows")
struct UpcomingContentTests {
    private let now = Fixture.date(2026, 11, 16, 10)

    /// M1…M9, on 1…9 December.
    private let nine = (1 ... 9).map { Fixture.milestone(title: "M\($0)", target: Fixture.day(2026, 12, $0)) }

    private func resolve(_ milestones: [Milestone]?, _ size: FaceSize) -> UpcomingContent {
        UpcomingContent.resolve(milestones: milestones, size: size, now: now, calendar: Fixture.calendar)
    }

    /// @spec WIDGET-LIST-001
    @Test("Rows are active milestones in display order: three at medium, seven at large")
    func rows() {
        var all = Array(nine.reversed())
        all[0].isArchived = true // M9
        let past = Fixture.milestone(title: "Past", target: Fixture.day(2026, 11, 1))
        #expect(resolve(all, .medium) == .rows(Array(nine.prefix(3))))
        #expect(resolve(all, .large) == .rows(Array(nine.prefix(7))))
        #expect(resolve([past] + nine.prefix(2), .medium) == .rows(nine.prefix(2) + [past]))
        #expect(UpcomingContent.rowLimit(for: .medium) == 3)
        #expect(UpcomingContent.rowLimit(for: .large) == 7)
    }

    /// @spec WIDGET-LIST-005
    @Test("Nothing active asks for a milestone; an unreadable store says so")
    func messages() {
        #expect(resolve([], .medium) == .noMilestones)
        #expect(resolve(nil, .large) == .unavailable)
    }
}
