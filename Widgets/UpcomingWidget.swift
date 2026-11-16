import DaysUntilCore
import DaysUntilUI
import SwiftUI
import WidgetKit

struct UpcomingEntry: TimelineEntry {
    let date: Date
    let content: UpcomingContent
}

struct UpcomingTimelineProvider: TimelineProvider {
    /// @spec WIDGET-GALLERY-001
    func placeholder(in context: Context) -> UpcomingEntry {
        UpcomingEntry(date: .now, content: samples(for: context, now: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (UpcomingEntry) -> Void) {
        let now = Date.now
        let content = UpcomingContent.resolve(
            milestones: WidgetStore.allMilestones(now: now), size: context.family.faceSize, now: now
        )
        let shown = context.isPreview && content == .noMilestones ? samples(for: context, now: now) : content
        completion(UpcomingEntry(date: now, content: shown))
    }

    /// One entry for now and one per instant a count changes, with the rows
    /// decided again at each: a milestone that passes drops below the upcoming ones.
    /// @spec WIDGET-TIME-002, WIDGET-TIME-003
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<UpcomingEntry>) -> Void) {
        let now = Date.now
        let size = context.family.faceSize
        let stored = WidgetStore.allMilestones(now: now)
        func entry(at date: Date) -> UpcomingEntry {
            UpcomingEntry(date: date, content: UpcomingContent.resolve(milestones: stored, size: size, now: date))
        }
        let first = entry(at: now)
        guard !first.content.isMessage else {
            let retry = now.addingTimeInterval(messageRefreshInterval)
            return completion(Timeline(entries: [first], policy: .after(retry)))
        }
        let active = (stored ?? []).filter { !$0.isArchived }
        let later = RefreshSchedule.dates(for: active, from: now).map(entry(at:))
        completion(Timeline(entries: [first] + later, policy: .atEnd))
    }

    private func samples(for context: Context, now: Date) -> UpcomingContent {
        UpcomingContent.resolve(milestones: Milestone.samples(now: now), size: context.family.faceSize, now: now)
    }
}

struct UpcomingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UpcomingEntry

    var body: some View {
        switch entry.content {
        case let .rows(milestones):
            rows(milestones)
        case .noMilestones:
            WidgetMessageView.noMilestones
        case .unavailable:
            WidgetMessageView.unavailable
        }
    }

    /// @spec WIDGET-LIST-003, WIDGET-LIST-004
    private func rows(_ milestones: [Milestone]) -> some View {
        VStack(spacing: 0) {
            ForEach(milestones) { milestone in
                Link(destination: milestone.url) {
                    UpcomingRow(milestone: milestone, now: entry.date)
                }
                .frame(maxHeight: .infinity)
            }
            // Pad with empty slots so rows keep their height when the list is short.
            let limit = UpcomingContent.rowLimit(for: family.faceSize)
            ForEach(0 ..< max(limit - milestones.count, 0), id: \.self) { _ in
                Color.clear.frame(maxHeight: .infinity)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct UpcomingRow: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let milestone: Milestone
    let now: Date

    /// @spec WIDGET-LIST-002
    var body: some View {
        let countdown = milestone.countdown(now: now)
        let text = countdown.text
        HStack(spacing: 10) {
            SymbolMark(milestone: milestone)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(renderingMode == .fullColor ? milestone.theme.inkColor : .primary)
                .frame(width: 28, height: 28)
                .background {
                    if renderingMode == .fullColor {
                        Circle().fill(milestone.theme.background)
                    } else {
                        Circle().fill(.primary.opacity(0.15))
                    }
                }
            Text(milestone.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .layoutPriority(1)
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: -1) {
                milestone.valueText(for: countdown)
                    .multilineTextAlignment(.trailing)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .monospacedDigit()
                    .widgetAccentable()
                Text(text.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(milestone.title), \(text.sentence)")
    }
}

struct UpcomingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UpcomingWidget", provider: UpcomingTimelineProvider()) { entry in
            UpcomingWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming")
        .description("Your next few milestones in one list.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
