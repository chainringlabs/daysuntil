import DaysUntilCore
import SwiftData
import SwiftUI

@main
struct DaysUntilApp: App {
    /// Opening the store can fail (disk full, unreadable file). The result is
    /// kept so the window can explain the failure instead of the app crashing.
    private let store = Result { try MilestoneStore.makeContainer() }
    @State private var model = AppModel()

    var body: some Scene {
        Window("DaysUntil", id: "main") {
            switch store {
            case let .success(container):
                MilestoneGridView()
                    .modelContainer(container)
                    .environment(model)
            case let .failure(error):
                StoreErrorView(error: error)
            }
        }
        .defaultSize(width: 820, height: 580)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Milestone") { model.startNew() }
                    .keyboardShortcut("n")
                    .disabled(!canEdit)
            }
        }
    }

    private var canEdit: Bool {
        if case .success = store {
            true
        } else {
            false
        }
    }
}

/// Shown in place of the grid when the data store cannot be opened.
struct StoreErrorView: View {
    let error: Error

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't Open Your Milestones", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        }
        .frame(minWidth: 480, minHeight: 320)
    }
}
