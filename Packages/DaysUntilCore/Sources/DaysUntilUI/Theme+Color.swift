import DaysUntilCore
import SwiftUI

public extension RGB {
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

public extension Theme {
    var inkColor: Color {
        ink.color
    }

    var accentColor: Color {
        accent.color
    }

    /// The unfilled part of bars, rings and dots.
    var trackColor: Color {
        ink.color.opacity(Theme.trackOpacity)
    }

    /// Ink for text that is not the title or the value.
    var secondaryInkColor: Color {
        ink.color.opacity(Theme.secondaryTextOpacity)
    }

    var background: LinearGradient {
        LinearGradient(
            colors: [backgroundTop.color, backgroundBottom.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
