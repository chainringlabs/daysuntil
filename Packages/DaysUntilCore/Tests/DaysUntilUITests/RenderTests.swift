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

    @Test("Every style renders at every size", arguments: FaceStyle.allCases, FaceSize.allCases)
    func renders(style: FaceStyle, size: FaceSize) throws {
        for (index, milestone) in Milestone.samples().enumerated() {
            let renderer = ImageRenderer(content: MilestoneCard(milestone, style: style, size: size))
            renderer.scale = 2
            let image = try #require(renderer.nsImage)
            #expect(image.size == size.cardSize)
            try save(image, name: "\(size.rawValue)-\(style.rawValue)-\(index)")
        }
    }

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
