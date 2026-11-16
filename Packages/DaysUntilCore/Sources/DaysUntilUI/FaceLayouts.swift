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
                Text(context.dateLine).font(context.metrics.detail).opacity(0.6).padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A horizontal progress bar under the count.
struct BarFace: View {
    let context: FaceContext

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FaceHeader(context: context)
            Spacer(minLength: 2)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                HeroValue(context: context, fontSize: context.metrics.value)
                Text(context.text.label).font(context.metrics.caption.weight(.medium)).opacity(0.85)
            }
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
            VStack(spacing: 8) {
                ring
                FaceHeader(context: context)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var ring: some View {
        ProgressRing(context: context).overlay {
            VStack(spacing: -2) {
                HeroValue(context: context, fontSize: context.metrics.value)
                Text(context.text.label).font(context.metrics.detail.weight(.medium)).opacity(0.85)
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
