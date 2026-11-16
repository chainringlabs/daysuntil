@testable import DaysUntilCore
import Foundation
import Testing

@Suite("Editor rules")
struct EditorRulesTests {
    private let now = Fixture.date(2026, 11, 16, 15, 30)
    private let calendar = Fixture.calendar

    /// @spec APP-ACT-002
    @Test("A new draft is an untitled all-day milestone 30 days out with defaults")
    func newDraft() {
        let draft = EditorRules.newDraft(now: now, calendar: calendar)
        #expect(draft.title.isEmpty)
        #expect(!draft.includesTime)
        #expect(draft.targetDate == Fixture.day(2026, 12, 16))
        #expect(draft.startDate == nil)
        #expect(draft.symbol == "flag.fill")
        #expect(draft.themeID == Theme.default.id)
        #expect(!draft.isArchived)
        #expect(draft.createdAt == now)
    }

    /// @spec APP-ACT-004
    @Test("A duplicate has a new id and a copy title, and is otherwise equal")
    func duplicate() {
        var original = Fixture.milestone(
            title: "Trip",
            target: Fixture.day(2026, 12, 9),
            start: Fixture.day(2026, 11, 1)
        )
        original.themeID = "tide"
        original.isArchived = true
        var copy = EditorRules.duplicate(original)
        #expect(copy.id != original.id)
        #expect(copy.title == "Trip copy")
        copy.id = original.id
        copy.title = original.title
        #expect(copy == original)
    }

    /// @spec APP-EDIT-001
    @Test("A title needs a non-whitespace character and is stored trimmed")
    func title() {
        #expect(!EditorRules.canSave(title: ""))
        #expect(!EditorRules.canSave(title: "  \n\t "))
        #expect(EditorRules.canSave(title: " a "))
        #expect(EditorRules.cleanedTitle("  Lisbon trip \n") == "Lisbon trip")
    }

    /// @spec APP-EDIT-002
    @Test("Turning time on sets 9:00 AM on the same day; turning it off drops the time")
    func includesTime() {
        let allDay = Fixture.milestone(target: Fixture.day(2026, 12, 9), start: Fixture.day(2026, 11, 1))
        let timed = EditorRules.setIncludesTime(true, on: allDay, calendar: calendar)
        #expect(timed.includesTime)
        #expect(timed.targetDate == Fixture.date(2026, 12, 9, 9, 0))
        #expect(timed.startDate == Fixture.date(2026, 11, 1, 9, 0))

        let back = EditorRules.setIncludesTime(false, on: timed, calendar: calendar)
        #expect(back == allDay)
        // Already in the requested state: nothing changes.
        #expect(EditorRules.setIncludesTime(false, on: allDay, calendar: calendar) == allDay)
    }

    /// @spec APP-EDIT-003
    @Test("Tracking a start begins at the earlier of the added day and the target day")
    func tracksStart() {
        let addedEarlier = Fixture.milestone(target: Fixture.day(2026, 12, 9), created: Fixture.date(2026, 11, 2, 18))
        #expect(EditorRules.setTracksStart(true, on: addedEarlier, calendar: calendar).startDate == Fixture.day(
            2026,
            11,
            2
        ))

        let countUp = Fixture.milestone(target: Fixture.day(2024, 5, 1), created: Fixture.date(2026, 11, 2, 18))
        #expect(EditorRules.setTracksStart(true, on: countUp, calendar: calendar).startDate == Fixture.day(2024, 5, 1))

        let withStart = Fixture.milestone(target: Fixture.day(2026, 12, 9), start: Fixture.day(2026, 11, 1))
        #expect(EditorRules.setTracksStart(false, on: withStart, calendar: calendar).startDate == nil)
        // Already tracking: the chosen start is kept.
        #expect(EditorRules.setTracksStart(true, on: withStart, calendar: calendar) == withStart)
    }

    /// @spec APP-EDIT-004
    @Test("The progress line states what is true of the draft")
    func progressNote() {
        func note(_ milestone: Milestone) -> ProgressNote {
            EditorRules.progressNote(for: milestone, now: now, calendar: calendar)
        }
        let created = Fixture.date(2026, 11, 2, 18)
        let target = Fixture.day(2026, 12, 9)
        #expect(note(Fixture.milestone(target: target, created: created)) == .fromDayAdded)
        #expect(note(Fixture.milestone(target: Fixture.day(2024, 5, 1), created: created)) == .noneWithoutStart)
        #expect(note(Fixture.milestone(target: Fixture.day(2026, 11, 2), created: created)) == .noneWithoutStart)
        #expect(note(Fixture.milestone(target: target, start: Fixture.day(2026, 11, 1), created: created)) ==
            .fromStartDate)
        #expect(note(Fixture.milestone(target: target, start: target, created: created)) == .startNotBeforeTarget)
        #expect(note(Fixture.milestone(target: target, start: Fixture.day(2027, 1, 1), created: created)) ==
            .startNotBeforeTarget)
    }
}
