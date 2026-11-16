import AppKit
import DaysUntilCore
@testable import DaysUntilUI
import SwiftUI
import Testing

/// Renders every style at every size. This catches layouts that crash or
/// produce nothing; set `DAYSUNTIL_RENDER_DIR` to also keep the PNGs for a
/// visual check (`make gallery`).
@MainActor
@Suite("Face rendering")
struct RenderTests {
    static let outputDirectory = ProcessInfo.processInfo.environment["DAYSUNTIL_RENDER_DIR"]
        .map { URL(filePath: $0, directoryHint: .isDirectory) }

    /// @spec FACE-RENDER-001
    @Test("Every style renders at every size", arguments: FaceStyle.allCases, FaceSize.allCases)
    func renders(style: FaceStyle, size: FaceSize) throws {
        for (index, milestone) in Milestone.samples().enumerated() {
            try render(milestone, style: style, size: size, name: "\(size.rawValue)-\(style.rawValue)-\(index)")
        }
    }

    /// @spec FACE-RENDER-002
    @Test("Every kind of milestone renders in every style", arguments: FaceStyle.allCases, FaceSize.allCases)
    func rendersEveryKind(style: FaceStyle, size: FaceSize) throws {
        let now = Date.now
        let hour: TimeInterval = 3600
        let kinds: [String: Milestone] = [
            "progress": Milestone(title: "With progress", targetDate: now + 240 * hour, startDate: now - 240 * hour),
            "countup": Milestone(title: "Count-up", targetDate: now - 9000 * hour),
            "finalday": Milestone(
                title: "Final day", targetDate: now + 5 * hour, includesTime: true, startDate: now - 48 * hour
            ),
            "justpast": Milestone(title: "Just past", targetDate: now - 2 * hour, includesTime: true),
            "emoji": Milestone(title: "A long title that will not fit on one line", targetDate: now, symbol: "🎂"),
        ]
        for (kind, milestone) in kinds {
            try render(milestone, style: style, size: size, name: "kind-\(kind)-\(size.rawValue)-\(style.rawValue)")
        }
    }

    /// @spec FACE-A11Y-001
    @Test("The accessibility label reads title, count and percentage")
    func accessibilityLabel() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let day: TimeInterval = 86400
        let trip = Milestone(title: "Lisbon trip", targetDate: now + 23 * day, startDate: now - 40 * day)
        #expect(trip.accessibilityLabel(now: now, calendar: calendar) == "Lisbon trip, 23 days until, 63% complete")
        let moved = Milestone(title: "Moved in", targetDate: now - 412 * day, createdAt: now)
        #expect(moved.accessibilityLabel(now: now, calendar: calendar) == "Moved in, 412 days since")
    }

    private func render(_ milestone: Milestone, style: FaceStyle, size: FaceSize, name: String) throws {
        let renderer = ImageRenderer(content: MilestoneCard(milestone, style: style, size: size))
        renderer.scale = 2
        let image = try #require(renderer.nsImage)
        #expect(image.size == size.cardSize)
        try save(image, name: name)
    }

    /// @spec FACE-DOTS-001
    @Test("Dot layout keeps every dot inside its bounds", arguments: [1, 7, 30, 70, 112, 196])
    func dotLayout(count: Int) {
        let size = CGSize(width: 138, height: 90)
        let layout = DotLayout(count: count, in: size)
        let bounds = CGRect(origin: .zero, size: size).insetBy(dx: -0.001, dy: -0.001)
        for index in 0 ..< count {
            #expect(bounds.contains(layout.rect(for: index)))
        }
    }

    private func save(_ image: NSImage, name: String) throws {
        guard let directory = Self.outputDirectory else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bitmap = try #require(image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)))
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: directory.appending(path: "\(name).png"))
    }
}
