// Renders the iBrain app icon — purple gradient rounded square with a white
// brain glyph (SF Symbol), matching the iSuite icon family.
// Run via: swift Packaging/make-icon.swift <output-dir>
import AppKit

let sizes: [(name: String, points: Int, scale: Int)] = [
    ("icon_16x16", 16, 1), ("icon_16x16@2x", 16, 2),
    ("icon_32x32", 32, 1), ("icon_32x32@2x", 32, 2),
    ("icon_128x128", 128, 1), ("icon_128x128@2x", 128, 2),
    ("icon_256x256", 256, 1), ("icon_256x256@2x", 256, 2),
    ("icon_512x512", 512, 1), ("icon_512x512@2x", 512, 2),
]

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "iconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

func drawIcon(pixels: Int) -> NSImage {
    let size = CGFloat(pixels)
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let inset = size * 0.09
    let squircle = NSBezierPath(
        roundedRect: NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2),
        xRadius: size * 0.2,
        yRadius: size * 0.2
    )

    // Purple gradient background (iBrain purple flow)
    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.66, green: 0.33, blue: 0.97, alpha: 1),
        ending: NSColor(calibratedRed: 0.42, green: 0.18, blue: 0.85, alpha: 1)
    )
    gradient?.draw(in: squircle, angle: -90)

    // White brain glyph (SF Symbol), centered
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .medium)
    if let brain = NSImage(systemSymbolName: "brain", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let tinted = NSImage(size: brain.size)
        tinted.lockFocus()
        NSColor.white.set()
        let rect = NSRect(origin: .zero, size: brain.size)
        brain.draw(in: rect)
        rect.fill(using: .sourceAtop)
        tinted.unlockFocus()

        let glyphW = size * 0.56
        let glyphH = glyphW * (tinted.size.height / max(tinted.size.width, 1))
        let target = NSRect(
            x: (size - glyphW) / 2,
            y: (size - glyphH) / 2,
            width: glyphW,
            height: glyphH
        )
        tinted.draw(in: target, from: .zero, operation: .sourceOver, fraction: 1)
    } else {
        // Fallback: hand-drawn brain blob — overlapping white circles + folds
        let cx = size * 0.5, cy = size * 0.52
        let blob = NSBezierPath()
        for (dx, dy, r) in [(-0.13, 0.06, 0.15), (0.13, 0.06, 0.15), (-0.07, 0.16, 0.12),
                            (0.07, 0.16, 0.12), (0.0, 0.02, 0.17), (-0.15, -0.06, 0.11),
                            (0.15, -0.06, 0.11), (0.0, -0.12, 0.13)] {
            blob.appendOval(in: NSRect(
                x: cx + size * dx - size * r, y: cy + size * dy - size * r,
                width: size * r * 2, height: size * r * 2))
        }
        NSColor.white.setFill()
        blob.fill()
        // Center groove
        let groove = NSBezierPath()
        groove.lineWidth = max(size * 0.03, 1)
        groove.move(to: NSPoint(x: cx, y: cy - size * 0.22))
        groove.line(to: NSPoint(x: cx, y: cy + size * 0.26))
        NSColor(calibratedRed: 0.5, green: 0.24, blue: 0.9, alpha: 1).setStroke()
        groove.stroke()
    }

    image.unlockFocus()
    return image
}

for spec in sizes {
    let pixels = spec.points * spec.scale
    let image = drawIcon(pixels: pixels)
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { continue }
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent("\(spec.name).png")
    try? png.write(to: url)
}
print("✓ iconset written to \(outputDir)")
