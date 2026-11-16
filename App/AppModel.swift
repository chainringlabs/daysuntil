import DaysUntilCore
import Foundation
import Observation
import SwiftData
import WidgetKit

/// A milestone being created or edited in the editor sheet.
struct EditorDraft: Identifiable {
    var milestone: Milestone
    let isNew: Bool

    var id: UUID {
        milestone.id
    }
}

/// Window-level state shared between the menu commands and the views.
@MainActor
@Observable
final class AppModel {
    var draft: EditorDraft?

    func startNew(now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        let target = calendar.date(byAdding: .day, value: 30, to: today) ?? today
        draft = EditorDraft(milestone: Milestone(title: "", targetDate: target, createdAt: now), isNew: true)
    }

    func edit(_ milestone: Milestone) {
        draft = EditorDraft(milestone: milestone, isNew: false)
    }
}

/// Writes to the store. Every change saves immediately and asks WidgetKit to
/// redraw, so desktop widgets never show stale milestones.
@MainActor
struct MilestoneEditing {
    let context: ModelContext
    let records: [MilestoneRecord]

    func save(_ milestone: Milestone) {
        if let record = records.first(where: { $0.id == milestone.id }) {
            record.apply(milestone)
        } else {
            context.insert(MilestoneRecord(milestone))
        }
        commit()
    }

    func duplicate(_ milestone: Milestone) {
        var copy = milestone
        copy.id = UUID()
        copy.title = "\(milestone.title) copy"
        context.insert(MilestoneRecord(copy))
        commit()
    }

    func setArchived(_ archived: Bool, for milestone: Milestone) {
        var updated = milestone
        updated.isArchived = archived
        save(updated)
    }

    func delete(_ milestone: Milestone) {
        guard let record = records.first(where: { $0.id == milestone.id }) else { return }
        context.delete(record)
        commit()
    }

    private func commit() {
        do {
            try context.save()
        } catch {
            // Autosave will retry; the change is still in the context.
            assertionFailure("Saving milestones failed: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
