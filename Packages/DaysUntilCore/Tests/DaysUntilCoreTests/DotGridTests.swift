@testable import DaysUntilCore
import Testing

@Suite("Dot grid")
struct DotGridTests {
    /// @spec COUNT-DOTS-001, COUNT-DOTS-004
    @Test("Short spans get one dot per day")
    func days() {
        let grid = DotGrid(totalDays: 30, elapsedDays: 12, maxDots: 60)
        #expect(grid.unit == .day)
        #expect(grid.count == 30)
        #expect(grid.filled == 12)
        #expect(grid.legend == nil)
    }

    /// @spec COUNT-DOTS-001, COUNT-DOTS-002, COUNT-DOTS-004
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

    /// @spec COUNT-DOTS-002
    @Test("A finished span fills every dot, even a partial last bucket")
    func finished() {
        let grid = DotGrid(totalDays: 100, elapsedDays: 100, maxDots: 60)
        #expect(grid.filled == grid.count)
    }

    /// @spec COUNT-DOTS-003
    @Test("A span too long for years gets the limit's dots, filled in proportion")
    func overlong() {
        let years = 365
        let half = DotGrid(totalDays: years * 200, elapsedDays: years * 100, maxDots: 60)
        #expect(half.unit == .year)
        #expect(half.count == 60)
        #expect(half.filled == 30)

        // Past the point where filling by whole years would already look finished.
        let late = DotGrid(totalDays: years * 200, elapsedDays: years * 150, maxDots: 60)
        #expect(late.filled == 45)
        let nearlyDone = DotGrid(totalDays: years * 200, elapsedDays: years * 200 - 1, maxDots: 60)
        #expect(nearlyDone.filled == 59)
        let done = DotGrid(totalDays: years * 200, elapsedDays: years * 200, maxDots: 60)
        #expect(done.filled == 60)
    }

    /// @spec COUNT-DOTS-006
    @Test("Each size has its dot limit")
    func limits() {
        #expect(FaceSize.small.maxDots == 70)
        #expect(FaceSize.medium.maxDots == 112)
        #expect(FaceSize.large.maxDots == 196)
    }

    /// @spec COUNT-DOTS-005
    @Test("Out-of-range input is clamped rather than trusted")
    func clamped() {
        let grid = DotGrid(totalDays: 0, elapsedDays: -5, maxDots: 0)
        #expect(grid.count == 1)
        #expect(grid.filled == 0)
    }
}
