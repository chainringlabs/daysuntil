import DaysUntilCore
import SwiftUI
import WidgetKit

/// The colours a face draws with. In full colour they come from the theme;
/// when the system tints or dims a widget they collapse to `primary` so the
/// system can recolour them.
/// @spec FACE-COLOUR-001, FACE-COLOUR-002
struct FacePalette {
    let ink: Color
    /// Ink for every text that is not the title or the value.
    let secondary: Color
    let accent: Color
    let track: Color

    init(theme: Theme, renderingMode: WidgetRenderingMode) {
        if renderingMode == .fullColor {
            ink = theme.inkColor
            secondary = theme.secondaryInkColor
            accent = theme.accentColor
            track = theme.trackColor
        } else {
            ink = .primary
            secondary = .primary.opacity(Theme.secondaryTextOpacity)
            accent = .primary
            track = .primary.opacity(0.25)
        }
    }
}

/// Type sizes and stroke widths for each face size.
struct FaceMetrics {
    let hero: CGFloat
    let value: CGFloat
    /// The count inside the ring, sized to the ring rather than the card.
    let ringValue: CGFloat
    let title: Font
    let caption: Font
    let detail: Font
    let ringWidth: CGFloat
    let barHeight: CGFloat

    init(_ size: FaceSize) {
        switch size {
        case .small:
            (hero, value, ringValue, ringWidth, barHeight) = (58, 30, 30, 9, 8)
            (title, caption, detail) = (.subheadline, .caption, .caption2)
        case .medium:
            (hero, value, ringValue, ringWidth, barHeight) = (68, 36, 34, 11, 10)
            (title, caption, detail) = (.subheadline, .caption, .caption2)
        case .large:
            (hero, value, ringValue, ringWidth, barHeight) = (132, 64, 92, 22, 14)
            (title, caption, detail) = (.title3, .subheadline, .caption)
        }
    }

    func rounded(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

/// Everything a face layout needs, computed once per render.
struct FaceContext {
    let milestone: Milestone
    let countdown: Countdown
    let palette: FacePalette
    let metrics: FaceMetrics
    let size: FaceSize

    var text: CountdownText {
        countdown.text
    }

    var progress: Double {
        countdown.progress ?? 0
    }

    /// "Dec 9, 2026", with the time appended for timed milestones.
    /// @spec FACE-CONTENT-010
    var dateLine: String {
        let day = Date.FormatStyle.dateTime.month(.abbreviated).day().year()
        let shown = milestone.localDate(for: milestone.targetDate)
        return shown.formatted(milestone.includesTime ? day.hour().minute() : day)
    }

    /// The count's value: a system-driven clock in the final day and the
    /// first day past, static text otherwise.
    var value: Text {
        milestone.valueText(for: countdown)
    }
}
