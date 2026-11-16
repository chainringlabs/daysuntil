// Draws the app icon and writes every size the asset catalog needs.
// Usage: swift scripts/make-icon.swift App/Assets.xcassets/AppIcon.appiconset
import AppKit

func color(_ hex: UInt32) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

/// A rounded tile in the Tide theme with a three-quarter progress ring and a
/// short row of dots: the two marks the app is built around.
func drawIcon(pixels: Int) -> NSBitmapImageRep? {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = context
    let unit = CGFloat(pixels) / 1024

    let tile = NSRect(x: 100 * unit, y: 100 * unit, width: 824 * unit, height: 824 * unit)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 185 * unit, yRadius: 185 * unit)
    NSGradient(starting: color(0x1F5F8B), ending: color(0x123C5E))?.draw(in: shape, angle: -60)

    let center = NSPoint(x: 512 * unit, y: 548 * unit)
    let ring = NSBezierPath()
    ring.appendArc(withCenter: center, radius: 220 * unit, startAngle: 0, endAngle: 360)
    ring.lineWidth = 62 * unit
    color(0xEFF8FF).withAlphaComponent(0.2).setStroke()
    ring.stroke()

    let arc = NSBezierPath()
    arc.appendArc(withCenter: center, radius: 220 * unit, startAngle: 90, endAngle: 180, clockwise: true)
    arc.lineWidth = 62 * unit
    arc.lineCapStyle = .round
    color(0x7FE3D4).setStroke()
    arc.stroke()

    for index in 0 ..< 5 {
        let dot = NSRect(x: (332 + CGFloat(index) * 80) * unit, y: 190 * unit, width: 40 * unit, height: 40 * unit)
        (index < 4 ? color(0x7FE3D4) : color(0xEFF8FF).withAlphaComponent(0.25)).setFill()
        NSBezierPath(ovalIn: dot).fill()
    }
    return bitmap
}

let directory = URL(filePath: CommandLine.arguments.dropFirst().first ?? ".", directoryHint: .isDirectory)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        guard let png = drawIcon(pixels: points * scale)?.representation(using: .png, properties: [:]) else {
            fatalError("Could not render \(name)")
        }
        try png.write(to: directory.appending(path: name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}

let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: directory.appending(path: "Contents.json"))
