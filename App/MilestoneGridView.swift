import DaysUntilCore
import DaysUntilUI
import SwiftData
import SwiftUI

struct MilestoneGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppModel.self) private var model
    @Query private var records: [MilestoneRecord]

    @AppStorage("cardStyle") private var cardStyle = FaceStyle.number
    @State private var showArchived = false
    @State private var pendingDelete: Milestone?

    private var editing: MilestoneEditing {
        MilestoneEditing(context: modelContext, records: records)
    }

    var body: some View {
        @Bindable var model = model
        TimelineView(.everyMinute) { timeline in
            content(now: timeline.date)
        }
        .frame(minWidth: 420, minHeight: 320)
        .toolbar { toolbar }
        .sheet(item: $model.draft) { draft in
            MilestoneEditor(draft: draft, onSave: editing.save) { pendingDelete = $0 }
        }
        .confirmationDialog(
            "Delete “\(pendingDelete?.title ?? "")”?",
            isPresented: Binding(get: { pendingDelete != nil }, set: {
                if !$0 {
                    pendingDelete = nil
                }
            }),
            presenting: pendingDelete
        ) { milestone in
            Button("Delete", role: .destructive) { editing.delete(milestone) }
        } message: { _ in
            Text("Widgets showing this milestone will ask you to pick another.")
        }
        .onOpenURL(perform: open)
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let milestones = records.map(\.snapshot)
            .filter { $0.isArchived == showArchived }
            .sortedForDisplay(now: now)
        if milestones.isEmpty {
            EmptyStateView(showingArchived: showArchived) { model.startNew() }
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 18)], spacing: 18) {
                    ForEach(milestones) { card(for: $0, now: now) }
                }
                .padding(22)
            }
        }
    }

    private func card(for milestone: Milestone, now: Date) -> some View {
        Button { model.edit(milestone) } label: {
            MilestoneCard(milestone, style: cardStyle, now: now)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit…") { model.edit(milestone) }
            Button("Duplicate") { editing.duplicate(milestone) }
            Button(milestone.isArchived ? "Unarchive" : "Archive") {
                editing.setArchived(!milestone.isArchived, for: milestone)
            }
            Divider()
            Button("Delete…", role: .destructive) { pendingDelete = milestone }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("Card style", selection: $cardStyle) {
                ForEach(FaceStyle.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.segmented)
            .help("How milestones are drawn in this window")
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Toggle(isOn: $showArchived) {
                Label("Archived", systemImage: "archivebox")
            }
            .help("Show archived milestones")
            Button { model.startNew() } label: {
                Label("New Milestone", systemImage: "plus")
            }
            .help("New milestone")
        }
    }

    /// Handles `daysuntil://milestone/<id>`, the link behind every widget.
    private func open(_ url: URL) {
        guard let id = Milestone.id(from: url),
              let record = records.first(where: { $0.id == id }) else { return }
        showArchived = record.isArchived
        model.edit(record.snapshot)
    }
}

private struct EmptyStateView: View {
    let showingArchived: Bool
    let onNew: () -> Void

    var body: some View {
        if showingArchived {
            ContentUnavailableView(
                "Nothing Archived",
                systemImage: "archivebox",
                description: Text("Archive a milestone from its right-click menu to tuck it away here.")
            )
        } else {
            ContentUnavailableView {
                Label("No Milestones Yet", systemImage: "calendar.badge.clock")
            } description: {
                Text("""
                Add something to count down to, or count up from. \
                Then right-click the desktop, choose Edit Widgets, and add DaysUntil.
                """)
            } actions: {
                Button("New Milestone", action: onNew).buttonStyle(.borderedProminent)
            }
        }
    }
}
