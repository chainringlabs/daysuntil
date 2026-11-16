import Foundation

/// How a milestone is drawn on a card or widget.
public enum FaceStyle: String, CaseIterable, Identifiable, Sendable {
    case number
    case bar
    case ring
    case dots

    public var id: String {
        rawValue
    }

    public var name: String {
        switch self {
        case .number: "Number"
        case .bar: "Bar"
        case .ring: "Ring"
        case .dots: "Dots"
        }
    }

    /// @spec COUNT-STYLE-001
    /// The style actually drawn. Bar, ring and dots all need a progress span;
    /// a milestone without one falls back to the plain number.
    public func resolved(for countdown: Countdown) -> FaceStyle {
        countdown.progress == nil ? .number : self
    }
}

/// The three sizes a face is laid out for, matching the system widget families.
public enum FaceSize: String, CaseIterable, Sendable {
    case small
    case medium
    case large

    /// @spec COUNT-DOTS-006
    /// The most dots the dot style shows at this size before bucketing days
    /// into weeks, months or years.
    public var maxDots: Int {
        switch self {
        case .small: 70
        case .medium: 112
        case .large: 196
        }
    }
}
