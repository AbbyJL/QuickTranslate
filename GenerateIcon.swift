import AppKit
import CoreGraphics

// Generate app icon: white rounded square + blue circle + white bidirectional arrows
// macOS adds rounded corners automatically, so we draw a full square image

func generateAppIconPNG(size: CGFloat) -> NSImage {
    let imageSize = NSSize(width: size, height: size)
    let image = NSImage(size: imageSize)
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let s = size

    // White background (full square, macOS will round the corners)
    ctx.setFillColor(CGColor.white)
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

    // Blue circle in center
    let padding = s * 0.15
    let circleRect = CGRect(x: padding, y: padding, width: s - padding * 2, height: s - padding * 2)
    ctx.setFillColor(CGColor(red: 0.231, green: 0.349, blue: 0.596, alpha: 1.0)) // #3B5998
    ctx.fillEllipse(in: circleRect)

    // White bidirectional arrows
    let center = CGPoint(x: s / 2, y: s / 2)
    let arrowLen = s * 0.30
    let arrowGap = s * 0.065
    let headSize = s * 0.06
    let lw = max(s * 0.032, 1.5)

    ctx.setStrokeColor(CGColor.white)
    ctx.setLineWidth(lw)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Right arrow (top)
    let topY = center.y + arrowGap
    ctx.move(to: CGPoint(x: center.x - arrowLen / 2, y: topY))
    ctx.addLine(to: CGPoint(x: center.x + arrowLen / 2, y: topY))
    ctx.strokePath()
    ctx.move(to: CGPoint(x: center.x + arrowLen / 2 - headSize, y: topY - headSize))
    ctx.addLine(to: CGPoint(x: center.x + arrowLen / 2, y: topY))
    ctx.addLine(to: CGPoint(x: center.x + arrowLen / 2 - headSize, y: topY + headSize))
    ctx.strokePath()

    // Left arrow (bottom)
    let botY = center.y - arrowGap
    ctx.move(to: CGPoint(x: center.x + arrowLen / 2, y: botY))
    ctx.addLine(to: CGPoint(x: center.x - arrowLen / 2, y: botY))
    ctx.strokePath()
    ctx.move(to: CGPoint(x: center.x - arrowLen / 2 + headSize, y: botY - headSize))
    ctx.addLine(to: CGPoint(x: center.x - arrowLen / 2, y: botY))
    ctx.addLine(to: CGPoint(x: center.x - arrowLen / 2 + headSize, y: botY + headSize))
    ctx.strokePath()

    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else { return }
    try? data.write(to: URL(fileURLWithPath: path))
}

let dir = "/Users/cheese/Documents/workspace/trans/QuickTranslate"
let iconsetDir = dir + "/AppIcon.iconset"

let fm = FileManager.default
try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, sz) in sizes {
    savePNG(image: generateAppIconPNG(size: sz), path: "\(iconsetDir)/\(name).png")
    print("  \(name).png")
}

// Save 1024 preview
savePNG(image: generateAppIconPNG(size: 1024), path: dir + "/AppIcon_1024_preview.png")
print("Done!")
