// Draws the app icon. Usage: swift tools/make-icon.swift <output.png>
import AppKit

let size = 1024
let space = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let s = CGFloat(size)

// Background: deep indigo to teal.
let gradient = CGGradient(colorsSpace: space, colors: [
    CGColor(red: 0.13, green: 0.12, blue: 0.36, alpha: 1),
    CGColor(red: 0.07, green: 0.42, blue: 0.50, alpha: 1),
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])

// A portrait video card with a play triangle cut out of it.
let card = CGRect(x: s * 0.31, y: s * 0.19, width: s * 0.38, height: s * 0.62)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
ctx.addPath(CGPath(roundedRect: card, cornerWidth: s * 0.07, cornerHeight: s * 0.07, transform: nil))
let cx = card.midX + s * 0.012, cy = card.midY, r = s * 0.14
ctx.move(to: CGPoint(x: cx - r * 0.75, y: cy + r))
ctx.addLine(to: CGPoint(x: cx - r * 0.75, y: cy - r))
ctx.addLine(to: CGPoint(x: cx + r, y: cy))
ctx.closePath()
ctx.fillPath(using: .evenOdd)

// The slash, with a gap in the background colour either side of it.
func slash(width: CGFloat, color: CGColor) {
    ctx.setStrokeColor(color)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: s * 0.20, y: s * 0.80))
    ctx.addLine(to: CGPoint(x: s * 0.80, y: s * 0.20))
    ctx.strokePath()
}
slash(width: s * 0.105, color: CGColor(red: 0.10, green: 0.27, blue: 0.43, alpha: 1))
slash(width: s * 0.058, color: CGColor(red: 1.0, green: 0.42, blue: 0.36, alpha: 1))

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
