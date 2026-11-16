import DaysUntilCore
import SwiftData
import SwiftUI
import Synchronization
import WidgetKit

@main
struct DaysUntilWidgetBundle: WidgetBundle {
    var body: some Widget {
        MilestoneWidget()
        UpcomingWidget()
    }
}

/// The widget extension's read-only view of the store the app writes.
/// @spec WIDGET-STORE-001, WIDGET-STORE-002
enum WidgetStore {
    /// The open store. Only a successful open is kept, so a failure is
    /// retried on the next request instead of lasting for the process's life.
    private static let opened = Mutex<ModelContainer?>(nil)

    private static func container() -> ModelContainer? {
        opened.withLock { held in
            if held == nil {
                held = try? MilestoneStore.makeContainer()
            }
            return held
        }
    }

    /// Every stored milestone, archived included, in display order; `nil`
    /// when the store cannot be opened or read.
    static func allMilestones(now: Date = .now) -> [Milestone]? {
        guard let container = container() else { return nil }
        return try? MilestoneStore.milestones(in: container, includeArchived: true, now: now)
    }
}

extension WidgetFamily {
    var faceSize: FaceSize {
        switch self {
        case .systemMedium: .medium
        case .systemLarge, .systemExtraLarge: .large
        default: .small
        }
    }
}

/// How long a widget showing a message waits before asking for a new
/// timeline, so a failed read recovers without the app.
/// @spec WIDGET-TIME-002
let messageRefreshInterval: TimeInterval = 15 * 60

/// What a widget shows when it has no milestone to draw.
struct WidgetMessageView: View {
    let symbol: String
    let message: String

    static let noMilestones = WidgetMessageView(
        symbol: "calendar.badge.plus",
        message: "Add a milestone in DaysUntil"
    )
    static let removed = WidgetMessageView(
        symbol: "questionmark.circle",
        message: "Milestone removed. Edit this widget to pick another."
    )
    static let unavailable = WidgetMessageView(
        symbol: "exclamationmark.triangle",
        message: "Couldn't load milestones. Open DaysUntil."
    )

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.title2)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .containerBackground(.background, for: .widget)
    }
}
