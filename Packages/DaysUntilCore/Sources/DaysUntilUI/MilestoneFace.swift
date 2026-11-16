import DaysUntilCore
import SwiftUI
import WidgetKit

/// A milestone drawn in one of the four styles, without a background. Widgets
/// put it over a container background; the app wraps it in `MilestoneCard`.
public struct MilestoneFace: View {
    private let milestone: Milestone
    private let style: FaceStyle
    private let size: FaceSize
    private let now: Date

    @Environment(\.widgetRenderingMode) private var renderingMode

    public init(_ milestone: Milestone, style: FaceStyle, size: FaceSize, now: Date = .now) {
        self.milestone = milestone
        self.style = style
        self.size = size
        self.now = now
    }

    /// @spec FACE-RENDER-001, FACE-RENDER-002, FACE-CONTENT-001, FACE-A11Y-001
    public var body: some View {
        let countdown = milestone.countdown(now: now)
        let context = FaceContext(
            milestone: milestone,
            countdown: countdown,
            palette: FacePalette(theme: milestone.theme, renderingMode: renderingMode),
            metrics: FaceMetrics(size),
            size: size
        )
        layout(for: context)
            .foregroundStyle(context.palette.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(milestone.accessibilityLabel(now: now))
    }

    /// @spec FACE-CONTENT-002
    @ViewBuilder
    private func layout(for context: FaceContext) -> some View {
        switch style.resolved(for: context.countdown) {
        case .number: NumberFace(context: context)
        case .bar: BarFace(context: context)
        case .ring: RingFace(context: context)
        case .dots: DotsFace(context: context)
        }
    }
}

/// A face on its theme background with rounded corners, sized like a widget.
/// Used by the app's grid and the editor preview.
public struct MilestoneCard: View {
    private let milestone: Milestone
    private let style: FaceStyle
    private let size: FaceSize
    private let now: Date

    public init(_ milestone: Milestone, style: FaceStyle, size: FaceSize = .small, now: Date = .now) {
        self.milestone = milestone
        self.style = style
        self.size = size
        self.now = now
    }

    /// @spec FACE-RENDER-003
    public var body: some View {
        MilestoneFace(milestone, style: style, size: size, now: now)
            .padding(16)
            .frame(width: size.cardSize.width, height: size.cardSize.height)
            .background(milestone.theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

public extension FaceSize {
    /// Approximate macOS widget dimensions, so cards preview widgets faithfully.
    var cardSize: CGSize {
        switch self {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 356, height: 170)
        case .large: CGSize(width: 356, height: 372)
        }
    }
}

#Preview("Styles") {
    let samples = Milestone.samples()
    return VStack(spacing: 16) {
        HStack(spacing: 16) {
            ForEach(FaceStyle.allCases) { MilestoneCard(samples[$0 == .dots ? 2 : 0], style: $0) }
        }
        HStack(spacing: 16) {
            MilestoneCard(samples[1], style: .ring, size: .medium)
            MilestoneCard(samples[3], style: .number, size: .medium)
        }
    }
    .padding()
}
