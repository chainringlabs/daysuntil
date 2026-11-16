import DaysUntilCore
import DaysUntilUI
import SwiftUI
import WidgetKit

struct UpcomingEntry: TimelineEntry {
    let date: Date
    let milestones: [Milestone]
}

struct UpcomingTimelineProvider: TimelineProvider {
    func placeholder(in _: Context) -> UpcomingEntry {
        UpcomingEntry(date: .now, milestones: Milestone.samples())
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (UpcomingEntry) -> Void) {
        let stored = WidgetStore.milestones()
        let shown = stored.isEmpty && context.isPreview ? Milestone.samples() : stored
        completion(UpcomingEntry(date: .now, milestones: shown))
    }

    func getTimeline(in _: Context, completion: @escaping @Sendable (Timeline<UpcomingEntry>) -> Void) {
        let now = Date.now
        let milestones = WidgetStore.milestones(now: now)
        // Re-sort at each entry: a milestone that passes drops below the upcoming ones.
        let dates = [now] + RefreshSchedule.dates(for: milestones, from: now)
        let entries = dates.map { UpcomingEntry(date: $0, milestones: milestones.sortedForDisplay(now: $0)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct UpcomingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UpcomingEntry

    private var rowLimit: Int {
        family == .systemLarge ? 7 : 3
    }

    var body: some View {
        if entry.milestones.isEmpty {
            WidgetMessageView(symbol: "calendar.badge.plus", message: "Add a milestone in DaysUntil")
        } else {
            VStack(spacing: 0) {
                ForEach(entry.milestones.prefix(rowLimit)) { milestone in
                    Link(destination: milestone.url) {
                        UpcomingRow(milestone: milestone, now: entry.date)
                    }
                    .frame(maxHeight: .infinity)
                }
                // Pad with empty slots so rows keep their height when the list is short.
                ForEach(0 ..< max(rowLimit - entry.milestones.count, 0), id: \.self) { _ in
                    Color.clear.frame(maxHeight: .infinity)
                }
            }
            .containerBackground(.background, for: .widget)
        }
    }
}

struct UpcomingRow: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let milestone: Milestone
    let now: Date

    var body: some View {
        let text = milestone.countdown(now: now).text
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
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: -1) {
                Text(text.value)
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
