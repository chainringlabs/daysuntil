import DaysUntilCore
import SwiftUI
import WidgetKit

/// Symbol and title, the top line of most faces.
struct FaceHeader: View {
    let context: FaceContext

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            SymbolMark(milestone: context.milestone)
                .foregroundStyle(context.palette.accent)
                .widgetAccentable()
            Text(context.milestone.title)
                .lineLimit(context.size == .large ? 2 : 1)
        }
        .font(context.metrics.title.weight(.semibold))
    }
}

/// A milestone's SF Symbol, or its emoji drawn as text.
public struct SymbolMark: View {
    let milestone: Milestone

    public init(milestone: Milestone) {
        self.milestone = milestone
    }

    public var body: some View {
        if milestone.symbolIsEmoji {
            Text(milestone.symbol)
        } else {
            Image(systemName: milestone.symbol)
        }
    }
}

/// The big value. On a timed milestone's final day it becomes a live timer,
/// which the system keeps ticking without new widget timeline entries.
struct HeroValue: View {
    let context: FaceContext
    let fontSize: CGFloat

    var body: some View {
        Group {
            if context.countdown.isFinalDay {
                Text(context.milestone.targetDate, style: .timer)
            } else {
                Text(context.text.value)
            }
        }
        .font(context.metrics.rounded(fontSize))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.35)
    }
}

struct ProgressBar: View {
    let context: FaceContext

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(context.palette.track)
                Capsule()
                    .fill(context.palette.accent)
                    .frame(width: max(proxy.size.height, proxy.size.width * context.progress))
                    .widgetAccentable()
            }
        }
        .frame(height: context.metrics.barHeight)
    }
}

struct ProgressRing: View {
    let context: FaceContext

    var body: some View {
        ZStack {
            Circle().stroke(context.palette.track, lineWidth: context.metrics.ringWidth)
            Circle()
                .trim(from: 0, to: max(context.progress, 0.003))
                .stroke(
                    context.palette.accent,
                    style: StrokeStyle(lineWidth: context.metrics.ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
        }
        .padding(context.metrics.ringWidth / 2)
        .aspectRatio(1, contentMode: .fit)
    }
}
