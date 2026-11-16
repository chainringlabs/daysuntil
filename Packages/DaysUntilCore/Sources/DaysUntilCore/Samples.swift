import Foundation

public extension Milestone {
    /// Representative milestones for previews, widget placeholders and the
    /// widget gallery. Dates are relative to `now` so they never go stale.
    static func samples(now: Date = .now, calendar: Calendar = .current) -> [Milestone] {
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) ?? now
        }
        return [
            Milestone(
                title: "Lisbon trip", targetDate: day(23), startDate: day(-40),
                symbol: "airplane", themeID: "tide", createdAt: day(-40)
            ),
            Milestone(
                title: "Marathon", targetDate: day(96), startDate: day(-84),
                symbol: "figure.run", themeID: "ember", createdAt: day(-84)
            ),
            Milestone(
                title: "Thesis deadline", targetDate: day(9), startDate: day(-171),
                symbol: "book.closed.fill", themeID: "ink", createdAt: day(-171)
            ),
            Milestone(
                title: "Moved in", targetDate: day(-412),
                symbol: "house.fill", themeID: "dune", createdAt: day(-10)
            ),
        ]
    }

    /// The single milestone shown by widget placeholders.
    static func sample(now: Date = .now) -> Milestone {
        samples(now: now)[0]
    }
}
