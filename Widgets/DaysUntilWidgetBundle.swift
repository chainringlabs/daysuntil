import DaysUntilCore
import SwiftData
import SwiftUI
import WidgetKit

@main
struct DaysUntilWidgetBundle: WidgetBundle {
    var body: some Widget {
        MilestoneWidget()
        UpcomingWidget()
    }
}

/// The widget extension's read-only view of the store the app writes.
enum WidgetStore {
    /// `nil` when the store cannot be opened; widgets then show their empty state.
    static let container = try? MilestoneStore.makeContainer()

    /// Active milestones in display order; empty on any failure.
    static func milestones(now: Date = .now) -> [Milestone] {
        guard let container else { return [] }
        return (try? MilestoneStore.milestones(in: container, now: now)) ?? []
    }

    static func milestone(id: UUID) -> Milestone? {
        guard let container else { return nil }
        return try? MilestoneStore.milestone(id: id, in: container)
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

/// What a widget shows when it has no milestone to draw.
struct WidgetMessageView: View {
    let symbol: String
    let message: String

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
