@testable import DaysUntilCore
import Testing

@Suite("Dot grid")
struct DotGridTests {
    @Test("Short spans get one dot per day")
    func days() {
        let grid = DotGrid(totalDays: 30, elapsedDays: 12, maxDots: 60)
        #expect(grid.unit == .day)
        #expect(grid.count == 30)
        #expect(grid.filled == 12)
        #expect(grid.legend == nil)
    }

    @Test("Longer spans bucket into the smallest unit that fits")
    func buckets() {
        let weeks = DotGrid(totalDays: 100, elapsedDays: 50, maxDots: 60)
        #expect(weeks.unit == .week)
        #expect(weeks.count == 15)
        #expect(weeks.filled == 7)
        #expect(weeks.legend == "1 dot = 1 week")

        let months = DotGrid(totalDays: 1000, elapsedDays: 0, maxDots: 60)
        #expect(months.unit == .month)
        #expect(months.count == 34)
    }

    @Test("A finished span fills every dot, even a partial last bucket")
    func finished() {
        let grid = DotGrid(totalDays: 100, elapsedDays: 100, maxDots: 60)
        #expect(grid.filled == grid.count)
    }

    @Test("Enormous spans cap at the dot limit")
    func capped() {
        let grid = DotGrid(totalDays: 365 * 200, elapsedDays: 365, maxDots: 60)
        #expect(grid.unit == .year)
        #expect(grid.count == 60)
        #expect(grid.filled == 1)
    }

    @Test("Out-of-range input is clamped rather than trusted")
    func clamped() {
        let grid = DotGrid(totalDays: 0, elapsedDays: -5, maxDots: 0)
        #expect(grid.count == 1)
        #expect(grid.filled == 0)
    }
}
