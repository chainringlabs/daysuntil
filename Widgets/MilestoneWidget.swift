import DaysUntilCore
import DaysUntilUI
import SwiftUI
import WidgetKit

struct MilestoneEntry: TimelineEntry {
    let date: Date
    let content: WidgetContent
    let style: FaceStyle
}

struct MilestoneTimelineProvider: AppIntentTimelineProvider {
    /// @spec WIDGET-GALLERY-001
    func placeholder(in _: Context) -> MilestoneEntry {
        MilestoneEntry(date: .now, content: .milestone(.sample()), style: .number)
    }

    func snapshot(for configuration: MilestoneWidgetIntent, in context: Context) async -> MilestoneEntry {
        let now = Date.now
        let style = configuration.style.faceStyle
        let content = WidgetContent.resolve(
            milestones: WidgetStore.allMilestones(now: now), chosenID: configuration.milestone?.id, now: now
        )
        if context.isPreview, content == .noMilestones {
            // The widget gallery should show what the widget looks like, not an instruction.
            return MilestoneEntry(date: now, content: .milestone(.sample(now: now)), style: style)
        }
        return MilestoneEntry(date: now, content: content, style: style)
    }

    /// One entry for now and one per instant a count changes. What to show is
    /// decided again for each entry, so a widget with no milestone chosen
    /// moves to the next milestone at the right moment by itself.
    /// @spec WIDGET-TIME-001, WIDGET-TIME-002
    func timeline(for configuration: MilestoneWidgetIntent, in _: Context) async -> Timeline<MilestoneEntry> {
        let now = Date.now
        let style = configuration.style.faceStyle
        let chosenID = configuration.milestone?.id
        let stored = WidgetStore.allMilestones(now: now)
        func entry(at date: Date) -> MilestoneEntry {
            let content = WidgetContent.resolve(milestones: stored, chosenID: chosenID, now: date)
            return MilestoneEntry(date: date, content: content, style: style)
        }
        let first = entry(at: now)
        guard !first.content.isMessage else {
            return Timeline(entries: [first], policy: .after(now.addingTimeInterval(messageRefreshInterval)))
        }
        // The milestones this widget could show: the chosen one, or any active one.
        let candidates = (stored ?? []).filter { !$0.isArchived && (chosenID == nil || $0.id == chosenID) }
        let later = RefreshSchedule.dates(for: candidates, from: now).map(entry(at:))
        return Timeline(entries: [first] + later, policy: .atEnd)
    }
}

struct MilestoneWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MilestoneEntry

    /// @spec WIDGET-SHOW-006, WIDGET-SHOW-007
    var body: some View {
        switch entry.content {
        case let .milestone(milestone):
            MilestoneFace(milestone, style: entry.style, size: family.faceSize, now: entry.date)
                .containerBackground(for: .widget) { milestone.theme.background }
                .widgetURL(milestone.url)
        case .noMilestones:
            WidgetMessageView.noMilestones
        case .removed:
            WidgetMessageView.removed
        case .unavailable:
            WidgetMessageView.unavailable
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
