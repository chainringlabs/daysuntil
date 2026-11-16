import Foundation

/// A colour as 0xRRGGBB. Kept UI-free so the core has no SwiftUI dependency.
public struct RGB: Hashable, Sendable {
    public let hex: UInt32

    public init(_ hex: UInt32) {
        self.hex = hex
    }

    public var red: Double {
        Double((hex >> 16) & 0xFF) / 255
    }

    public var green: Double {
        Double((hex >> 8) & 0xFF) / 255
    }

    public var blue: Double {
        Double(hex & 0xFF) / 255
    }

    /// WCAG relative luminance.
    public var luminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// This colour drawn over `background` at `opacity`, as an opaque colour.
    public func blended(over background: RGB, opacity: Double) -> RGB {
        func mix(_ top: UInt32, _ bottom: UInt32) -> UInt32 {
            UInt32((Double(top) * opacity + Double(bottom) * (1 - opacity)).rounded())
        }
        let red = mix((hex >> 16) & 0xFF, (background.hex >> 16) & 0xFF)
        let green = mix((hex >> 8) & 0xFF, (background.hex >> 8) & 0xFF)
        let blue = mix(hex & 0xFF, background.hex & 0xFF)
        return RGB(red << 16 | green << 8 | blue)
    }

    /// WCAG contrast ratio against another colour, 1...21.
    public func contrast(with other: RGB) -> Double {
        let lighter = max(luminance, other.luminance)
        let darker = min(luminance, other.luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// @spec THEME-004, THEME-005, THEME-006
/// A built-in look for a milestone: a two-stop background, an ink colour for
/// text, and an accent for the filled part of progress marks.
public struct Theme: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let backgroundTop: RGB
    public let backgroundBottom: RGB
    public let ink: RGB
    public let accent: RGB

    /// @spec THEME-001
    public static let all: [Theme] = [
        ember,
        Theme(id: "tide", name: "Tide", top: 0x1F5F8B, bottom: 0x123C5E, ink: 0xEFF8FF, accent: 0x7FE3D4),
        Theme(id: "moss", name: "Moss", top: 0x406536, bottom: 0x2A4726, ink: 0xF4F8EC, accent: 0xE3E36A),
        Theme(id: "plum", name: "Plum", top: 0x6B3A75, bottom: 0x40204A, ink: 0xFBF1FF, accent: 0xFF9EC4),
        Theme(id: "dune", name: "Dune", top: 0xF0DFC0, bottom: 0xDDC597, ink: 0x3A2C17, accent: 0xB4501F),
        Theme(id: "frost", name: "Frost", top: 0xEAF1F5, bottom: 0xCBD9E2, ink: 0x1C2B36, accent: 0x1F6FB0),
        Theme(id: "slate", name: "Slate", top: 0x3B4450, bottom: 0x22282F, ink: 0xF2F4F6, accent: 0xFF8552),
        Theme(id: "ink", name: "Ink", top: 0x1B1B1F, bottom: 0x0C0C0E, ink: 0xF5F2EA, accent: 0xC9F26B),
    ]

    private static let ember = Theme(
        id: "ember", name: "Ember", top: 0xA83414, bottom: 0x7E2610, ink: 0xFFF6EC, accent: 0xFFE08A
    )

    /// The theme of a new milestone, and the fallback for an unknown id.
    /// @spec THEME-002
    public static let `default` = ember

    /// The one opacity ink is drawn at for dimmed text. Every theme keeps
    /// 4.5:1 contrast at this opacity; see the theme tests.
    /// @spec THEME-007
    public static let secondaryTextOpacity = 0.8
    /// The opacity of ink used for the unfilled part of bars, rings and dots.
    /// @spec THEME-008
    public static let trackOpacity = 0.2

    /// @spec THEME-003
    /// Looks a theme up by id, falling back to the default for unknown ids so
    /// a removed or renamed theme never breaks a stored milestone.
    public static func named(_ id: String) -> Theme {
        all.first { $0.id == id } ?? .default
    }

    private init(id: String, name: String, top: UInt32, bottom: UInt32, ink: UInt32, accent: UInt32) {
        self.id = id
        self.name = name
        backgroundTop = RGB(top)
        backgroundBottom = RGB(bottom)
        self.ink = RGB(ink)
        self.accent = RGB(accent)
    }
}
