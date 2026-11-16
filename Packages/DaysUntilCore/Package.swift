// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "DaysUntilCore",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "DaysUntilCore", targets: ["DaysUntilCore"]),
        .library(name: "DaysUntilUI", targets: ["DaysUntilUI"]),
    ],
    targets: [
        // Model, persistence and date math. No UI imports.
        .target(name: "DaysUntilCore"),
        // SwiftUI views shared by the app and the widget extension.
        .target(name: "DaysUntilUI", dependencies: ["DaysUntilCore"]),
        .testTarget(name: "DaysUntilCoreTests", dependencies: ["DaysUntilCore"]),
        .testTarget(name: "DaysUntilUITests", dependencies: ["DaysUntilUI"]),
    ],
    swiftLanguageModes: [.v6]
)
