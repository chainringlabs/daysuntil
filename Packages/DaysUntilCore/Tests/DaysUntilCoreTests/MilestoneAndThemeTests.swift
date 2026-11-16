@testable import DaysUntilCore
import Foundation
import Testing

@Suite("Milestone")
struct MilestoneTests {
    /// @spec COUNT-MS-001, COUNT-MS-002
    @Test("Deep links carry the id and only milestone links parse")
    func deepLink() throws {
        let milestone = Fixture.milestone(target: .now)
        #expect(milestone.url.absoluteString == "daysuntil://milestone/\(milestone.id.uuidString)")
        #expect(Milestone.id(from: milestone.url) == milestone.id)
        for other in [
            "https://example.com/milestone/x",
            "daysuntil://other/\(milestone.id)",
            "daysuntil://milestone/x",
        ] {
            #expect(try Milestone.id(from: #require(URL(string: other))) == nil)
        }
    }

    /// @spec COUNT-MS-003
    @Test("Emoji symbols are told apart from SF Symbol names")
    func emoji() {
        var milestone = Fixture.milestone(target: .now)
        milestone.symbol = "🎂"
        #expect(milestone.symbolIsEmoji)
        milestone.symbol = "figure.run"
        #expect(!milestone.symbolIsEmoji)
    }

    /// @spec COUNT-SAMPLE-001
    @Test("Samples follow the supplied now and cover the kinds of milestone")
    func samples() {
        let now = Fixture.date(2031, 3, 3, 12)
        let samples = Milestone.samples(now: now, calendar: Fixture.calendar)
        let countdowns = samples.map { Fixture.countdown($0, now: now) }
        #expect(countdowns.contains { $0.phase == .upcoming && $0.progress != nil })
        #expect(countdowns.contains { $0.phase == .past && $0.progress == nil })
        #expect(samples.contains { $0.includesTime })
        #expect(samples.contains { $0.symbolIsEmoji })
        // Relative, not fixed: every sample is within a few years of the supplied now.
        #expect(countdowns.allSatisfy { $0.days < 1500 })
    }
}

@Suite("Themes")
struct ThemeTests {
    /// @spec THEME-001
    @Test("The built-in themes, in order, with unique ids")
    func builtIn() {
        #expect(Theme.all.map(\.name) == ["Ember", "Tide", "Moss", "Plum", "Dune", "Frost", "Slate", "Ink"])
        #expect(Set(Theme.all.map(\.id)).count == Theme.all.count)
    }

    /// @spec THEME-002, THEME-003
    @Test("Ember is the default, and unknown ids fall back to it")
    func defaultTheme() {
        #expect(Theme.default.id == "ember")
        #expect(Theme.named("nope") == Theme.default)
        #expect(Theme.named("tide").name == "Tide")
    }

    /// @spec THEME-004, THEME-006
    @Test("Ink and accent meet their contrast minimums on both background stops", arguments: Theme.all)
    func contrast(theme: Theme) {
        for background in [theme.backgroundTop, theme.backgroundBottom] {
            #expect(theme.ink.contrast(with: background) >= 4.5, "\(theme.name) ink")
            #expect(theme.accent.contrast(with: background) >= 3, "\(theme.name) accent")
        }
    }

    /// @spec THEME-005
    @Test("Secondary text, as drawn, still meets 4.5:1 on both background stops", arguments: Theme.all)
    func secondaryContrast(theme: Theme) {
        for background in [theme.backgroundTop, theme.backgroundBottom] {
            let drawn = theme.ink.blended(over: background, opacity: Theme.secondaryTextOpacity)
            #expect(drawn.contrast(with: background) >= 4.5, "\(theme.name) secondary text")
        }
    }

    /// @spec THEME-007, THEME-008
    @Test("Secondary text is drawn at 80% and the track at 20%")
    func opacities() {
        #expect(Theme.secondaryTextOpacity == 0.8)
        #expect(Theme.trackOpacity == 0.2)
    }
}
