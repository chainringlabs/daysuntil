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
    /// The milestone open in the editor. It is the only unsaved state in the
    /// app, so nothing replaces it while it is set.
    private(set) var draft: EditorDraft?
    /// Whether the grid shows archived milestones instead of active ones.
    var showArchived = false

    var isEditing: Bool {
        draft != nil
    }

    /// Opens the editor on a new draft and shows the active grid, where the
    /// new milestone will appear. Does nothing while the editor is open.
    /// @spec APP-ACT-001, APP-ACT-002, APP-EDIT-011
    func startNew(now: Date = .now, calendar: Calendar = .current) {
        guard !isEditing else { return }
        showArchived = false
        draft = EditorDraft(milestone: EditorRules.newDraft(now: now, calendar: calendar), isNew: true)
    }

    /// Opens the editor on a stored milestone. Does nothing while the editor is open.
    /// @spec APP-ACT-003, APP-EDIT-011
    func edit(_ milestone: Milestone) {
        guard !isEditing else { return }
        draft = EditorDraft(milestone: milestone, isNew: false)
    }

    /// Called when the person closes the editor.
    func closeEditor() {
        draft = nil
    }
}

/// Writes to the store. Every change saves immediately and asks WidgetKit to
/// redraw, so desktop widgets never show stale milestones.
/// @spec APP-WRITE-001
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

    /// @spec APP-ACT-004
    func duplicate(_ milestone: Milestone) {
        context.insert(MilestoneRecord(EditorRules.duplicate(milestone)))
        commit()
    }

    /// @spec APP-ACT-005
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
