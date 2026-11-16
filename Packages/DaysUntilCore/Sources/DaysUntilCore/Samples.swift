import Foundation

public extension Milestone {
    /// Representative milestones for previews, widget placeholders and the
    /// widget gallery. Dates are relative to `now` so they never go stale.
    /// @spec COUNT-SAMPLE-001
    static func samples(now: Date = .now, calendar: Calendar = .current) -> [Milestone] {
        let today = CalendarDay(containing: now, in: calendar)
        func day(_ offset: Int) -> Date {
            today.adding(days: offset).storedInstant
        }
        func added(_ offset: Int) -> Date {
            today.adding(days: offset).start(in: calendar)
        }
        let flight = Milestone(
            title: "Flight home", targetDate: day(3), symbol: "airplane.departure", themeID: "slate",
            createdAt: added(-4)
        )
        .convertedToTimed(hour: 18, minute: 30, calendar: calendar)
        return [
            Milestone(
                title: "Lisbon trip", targetDate: day(23), startDate: day(-40),
                symbol: "airplane", themeID: "tide", createdAt: added(-40)
            ),
            Milestone(
                title: "Marathon", targetDate: day(96), startDate: day(-84),
                symbol: "figure.run", themeID: "ember", createdAt: added(-84)
            ),
            Milestone(
                title: "Thesis deadline", targetDate: day(9), startDate: day(-171),
                symbol: "book.closed.fill", themeID: "ink", createdAt: added(-171)
            ),
            Milestone(
                title: "Moved in", targetDate: day(-412),
                symbol: "house.fill", themeID: "dune", createdAt: added(-10)
            ),
            Milestone(
                title: "Mum's birthday", targetDate: day(58), startDate: day(-12),
                symbol: "🎂", themeID: "plum", createdAt: added(-12)
            ),
            flight,
        ]
    }

    /// The single milestone shown by widget placeholders.
    static func sample(now: Date = .now, calendar: Calendar = .current) -> Milestone {
        samples(now: now, calendar: calendar)[0]
    }
}
