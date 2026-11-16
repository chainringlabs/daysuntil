import DaysUntilCore
import DaysUntilUI
import SwiftUI
import WidgetKit

struct MilestoneEntry: TimelineEntry {
    enum Content {
        case milestone(Milestone)
        /// The store has no active milestones at all.
        case noMilestones
        /// The configured milestone was deleted or archived.
        case missing
    }

    let date: Date
    let content: Content
    let style: FaceStyle
}

struct MilestoneTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> MilestoneEntry {
        MilestoneEntry(date: .now, content: .milestone(.sample()), style: .number)
    }

    func snapshot(for configuration: MilestoneWidgetIntent, in context: Context) async -> MilestoneEntry {
        let entry = entry(for: configuration, at: .now)
        if context.isPreview, case .noMilestones = entry.content {
            // The widget gallery should show what the widget looks like, not an empty state.
            return MilestoneEntry(date: .now, content: .milestone(.sample()), style: entry.style)
        }
        return entry
    }

    func timeline(for configuration: MilestoneWidgetIntent, in _: Context) async -> Timeline<MilestoneEntry> {
        let now = Date.now
        let first = entry(for: configuration, at: now)
        guard case let .milestone(milestone) = first.content else {
            return Timeline(entries: [first], policy: .never)
        }
        // One entry per upcoming change; the app also reloads timelines on every edit.
        let later = RefreshSchedule.dates(for: [milestone], from: now).map {
            MilestoneEntry(date: $0, content: first.content, style: first.style)
        }
        return Timeline(entries: [first] + later, policy: .atEnd)
    }

    private func entry(for configuration: MilestoneWidgetIntent, at date: Date) -> MilestoneEntry {
        let style = configuration.style.faceStyle
        let content: MilestoneEntry.Content
        if let chosen = configuration.milestone {
            let found = WidgetStore.milestone(id: chosen.id).flatMap { $0.isArchived ? nil : $0 }
            content = found.map { .milestone($0) } ?? .missing
        } else {
            content = WidgetStore.milestones(now: date).first.map { .milestone($0) } ?? .noMilestones
        }
        return MilestoneEntry(date: date, content: content, style: style)
    }
}

struct MilestoneWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MilestoneEntry

    var body: some View {
        switch entry.content {
        case let .milestone(milestone):
            MilestoneFace(milestone, style: entry.style, size: family.faceSize, now: entry.date)
                .containerBackground(for: .widget) { milestone.theme.background }
                .widgetURL(milestone.url)
        case .noMilestones:
            WidgetMessageView(symbol: "calendar.badge.plus", message: "Add a milestone in DaysUntil")
        case .missing:
            WidgetMessageView(
                symbol: "questionmark.circle",
                message: "Milestone removed. Edit this widget to pick another."
            )
        }
    }
}

struct MilestoneWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "MilestoneWidget",
            intent: MilestoneWidgetIntent.self,
            provider: MilestoneTimelineProvider()
        ) { entry in
            MilestoneWidgetView(entry: entry)
        }
        .configurationDisplayName("Milestone")
        .description("One milestone as a number, bar, ring or dot grid.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
