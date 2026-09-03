// Draws the app icon and writes an .iconset directory ready for iconutil.
// Keeping the artwork as code means no binary asset in the repository, and
// recolouring it is a matter of editing the constants below.
//
//   swift Tools/make-icon.swift <output.iconset>

import AppKit
import Foundation

let backgroundTop = NSColor(srgbRed: 0.227, green: 0.227, blue: 0.235, alpha: 1)     // #3A3A3C
let backgroundBottom = NSColor(srgbRed: 0.110, green: 0.110, blue: 0.118, alpha: 1)  // #1C1C1E
let outline = NSColor.white
let charge = NSColor(srgbRed: 0.188, green: 0.820, blue: 0.345, alpha: 1)            // #30D158

/// Everything below is laid out on Apple's 1024 pt icon grid and scaled down,
/// so the proportions hold at every exported size.
func drawIcon(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(pixels) / 1024

    // The rounded square: 824 pt centred on the 1024 pt canvas, per Apple's grid.
    let plate = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let plateShape = NSBezierPath(roundedRect: plate, xRadius: 185 * s, yRadius: 185 * s)
    NSGradient(starting: backgroundTop, ending: backgroundBottom)!
        .draw(in: plateShape, angle: -90)

    // Battery body, drawn as a stroked outline.
    let stroke = 36 * s
    let body = NSRect(x: 239 * s, y: 387 * s, width: 500 * s, height: 250 * s)
    let bodyShape = NSBezierPath(roundedRect: body.insetBy(dx: stroke / 2, dy: stroke / 2),
                                 xRadius: 72 * s, yRadius: 72 * s)
    bodyShape.lineWidth = stroke
    outline.setStroke()
    bodyShape.stroke()

    // The charge level, deliberately low: this app is about the battery running out.
    let inner = body.insetBy(dx: stroke + 20 * s, dy: stroke + 20 * s)
    let level = NSRect(x: inner.minX, y: inner.minY,
                       width: inner.width * 0.38, height: inner.height)
    charge.setFill()
    NSBezierPath(roundedRect: level, xRadius: 34 * s, yRadius: 34 * s).fill()

    // The positive terminal.
    let nub = NSRect(x: body.maxX + 18 * s, y: 512 * s - 45 * s,
                     width: 28 * s, height: 90 * s)
    outline.setFill()
    NSBezierPath(roundedRect: nub, xRadius: 14 * s, yRadius: 14 * s).fill()

    return rep.representation(using: .png, properties: [:])!
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: make-icon.swift <output.iconset>\n".data(using: .utf8)!)
    exit(1)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.removeItem(at: output)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

// The names and sizes iconutil expects.
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let suffix = scale == 1 ? "" : "@2x"
        let name = "icon_\(base)x\(base)\(suffix).png"
        try drawIcon(pixels: base * scale).write(to: output.appendingPathComponent(name))
    }
}

print("Wrote \(output.path)")
