import DaysUntilCore
import DaysUntilUI
import SwiftUI

/// The add / edit sheet: a form on the left, a live widget preview on the right.
struct MilestoneEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var milestone: Milestone
    @AppStorage("previewStyle") private var previewStyle = FaceStyle.number

    private let isNew: Bool
    private let onSave: (Milestone) -> Void
    private let onDelete: (Milestone) -> Void

    init(draft: EditorDraft, onSave: @escaping (Milestone) -> Void, onDelete: @escaping (Milestone) -> Void) {
        _milestone = State(initialValue: draft.milestone)
        isNew = draft.isNew
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var trimmedTitle: String {
        milestone.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                MilestoneForm(milestone: $milestone)
                    .frame(width: 380)
                Divider()
                preview
            }
            Divider()
            buttons
        }
        .frame(height: 560)
    }

    private var preview: some View {
        VStack(spacing: 16) {
            Picker("Style", selection: $previewStyle) {
                ForEach(FaceStyle.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            MilestoneCard(previewed, style: previewStyle, size: .small)
            MilestoneCard(previewed, style: previewStyle, size: .medium)
            Text(previewNote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 396)
        .background(.quaternary.opacity(0.4))
    }

    /// The draft as it will be drawn; an empty title shows a stand-in.
    private var previewed: Milestone {
        var copy = milestone
        if trimmedTitle.isEmpty {
            copy.title = "Untitled"
        }
        return copy
    }

    private var previewNote: String {
        let countdown = milestone.countdown()
        if countdown.progress == nil, previewStyle != .number {
            return "Bar, ring and dots need a start date before the target, so this shows the number style."
        }
        if let weeks = countdown.weeksText {
            return "That's \(weeks)."
        }
        return "Pick the style per widget when you add it to the desktop."
    }

    private var buttons: some View {
        HStack {
            if !isNew {
                Button("Delete…", role: .destructive) {
                    dismiss()
                    onDelete(milestone)
                }
            }
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button(isNew ? "Add" : "Save") {
                milestone.title = trimmedTitle
                onSave(milestone)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(trimmedTitle.isEmpty)
        }
        .padding(16)
    }
}
