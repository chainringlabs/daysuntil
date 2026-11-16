import DaysUntilCore
import SwiftUI

/// The day count as the hero.
struct NumberFace: View {
    let context: FaceContext

    var body: some View {
        if context.size == .medium {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    FaceHeader(context: context)
                    Spacer(minLength: 4)
                    Text(context.dateLine).font(context.metrics.caption).opacity(0.7)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: -2) {
                    HeroValue(context: context, fontSize: context.metrics.hero)
                    Text(context.text.label).font(context.metrics.caption.weight(.medium)).opacity(0.85)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                FaceHeader(context: context)
                Spacer(minLength: 4)
                HeroValue(context: context, fontSize: context.metrics.hero)
                Text(context.text.label).font(context.metrics.caption.weight(.medium)).opacity(0.85)
                if context.size == .large {
                    LargeFooter(context: context, showsBar: false).padding(.top, 10)
                } else {
                    Text(context.dateLine).font(context.metrics.detail).opacity(0.6).padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// The extra room of a large face: optionally a progress bar, then the
/// percentage, the count restated in weeks, and the date.
struct LargeFooter: View {
    let context: FaceContext
    let showsBar: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsBar {
                ProgressBar(context: context)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(leading).fontWeight(.semibold)
                Spacer(minLength: 8)
                Text(context.dateLine).opacity(0.7)
            }
            .font(context.metrics.detail)
            .lineLimit(1)
        }
    }

    /// "63% · 3 weeks, 2 days", leaving out whichever part does not apply.
    private var leading: String {
        let parts = [context.countdown.percentText, context.countdown.weeksText].compactMap(\.self)
        return parts.joined(separator: " · ")
    }
}

/// A horizontal progress bar under the count.
struct BarFace: View {
    let context: FaceContext

    private var isLarge: Bool {
        context.size == .large
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FaceHeader(context: context)
            Spacer(minLength: 2)
            HStack(alignment: .firstTextBaseline, spacing: isLarge ? 8 : 5) {
                HeroValue(context: context, fontSize: isLarge ? context.metrics.hero * 0.8 : context.metrics.value)
                Text(context.text.label).font(context.metrics.caption.weight(.medium)).opacity(0.85)
            }
            if isLarge {
                LargeFooter(context: context, showsBar: true)
            } else {
                ProgressBar(context: context)
                HStack {
                    Text(context.countdown.percentText ?? "")
                    Spacer()
                    Text(context.dateLine).opacity(0.7)
                }
                .font(context.metrics.detail.weight(.medium))
                .lineLimit(1)
            }
        }
    }
}

/// A progress ring with the count in its centre.
struct RingFace: View {
    let context: FaceContext

    var body: some View {
        if context.size == .medium {
            HStack(spacing: 16) {
                ring
                VStack(alignment: .leading, spacing: 4) {
                    FaceHeader(context: context)
                    Spacer(minLength: 0)
                    Text(context.countdown.percentText ?? "").font(context.metrics.rounded(context.metrics.value))
                    Text(context.dateLine).font(context.metrics.caption).opacity(0.7)
                }
                Spacer(minLength: 0)
            }
        } else {
            VStack(spacing: context.size == .large ? 12 : 8) {
                ring
                FaceHeader(context: context)
                if context.size == .large {
                    Text("\(context.countdown.percentText ?? "") · \(context.dateLine)")
                        .font(context.metrics.detail)
                        .opacity(0.7)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var ring: some View {
        ProgressRing(context: context).overlay {
            VStack(spacing: -2) {
                HeroValue(context: context, fontSize: context.metrics.ringValue)
                Text(context.text.label)
                    .font((context.size == .large ? context.metrics.caption : context.metrics.detail).weight(.medium))
                    .opacity(0.85)
            }
            .padding(context.metrics.ringWidth * 2)
        }
    }
}

/// One dot per day (or week, month, year for long spans), elapsed ones filled.
struct DotsFace: View {
    let context: FaceContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FaceHeader(context: context)
            if let grid = context.countdown.dotGrid(maxDots: context.size.maxDots) {
                DotGridView(grid: grid, palette: context.palette)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                footer(legend: context.size == .small ? nil : grid.legend)
            }
        }
    }

    private func footer(legend: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(context.text.sentence).fontWeight(.semibold)
            Spacer(minLength: 4)
            Text(legend ?? context.countdown.percentText ?? "").opacity(0.7)
        }
        .font(context.metrics.detail)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}
