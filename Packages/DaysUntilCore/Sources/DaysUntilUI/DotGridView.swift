import DaysUntilCore
import SwiftUI
import WidgetKit

/// Draws a `DotGrid`, choosing the column count that makes the dots as large
/// as the available space allows.
struct DotGridView: View {
    let grid: DotGrid
    let palette: FacePalette

    var body: some View {
        ZStack {
            layer(range: grid.filled ..< grid.count, color: palette.track)
            layer(range: 0 ..< grid.filled, color: palette.accent)
                .widgetAccentable()
        }
    }

    /// Filled and unfilled dots are separate layers so the system can tint
    /// only the filled ones when a widget is rendered in an accented mode.
    private func layer(range: Range<Int>, color: Color) -> some View {
        Canvas { context, size in
            let layout = DotLayout(count: grid.count, in: size)
            for index in range {
                context.fill(Path(ellipseIn: layout.rect(for: index)), with: .color(color))
            }
        }
    }
}

/// Positions `count` dots in a left-aligned grid inside a rectangle.
/// @spec FACE-DOTS-001
struct DotLayout {
    let columns: Int
    let cell: CGFloat
    /// Dot diameter as a share of the cell; the rest is the gap.
    static let fill: CGFloat = 0.72

    init(count: Int, in size: CGSize) {
        var best = (columns: 1, cell: CGFloat.zero)
        for columns in 1 ... max(count, 1) {
            let rows = (count + columns - 1) / columns
            let cell = min(size.width / CGFloat(columns), size.height / CGFloat(rows))
            if cell > best.cell {
                best = (columns, cell)
            }
        }
        columns = best.columns
        cell = best.cell
    }

    func rect(for index: Int) -> CGRect {
        let inset = cell * (1 - Self.fill) / 2
        return CGRect(
            x: CGFloat(index % columns) * cell + inset,
            y: CGFloat(index / columns) * cell + inset,
            width: cell * Self.fill,
            height: cell * Self.fill
        )
    }
}
