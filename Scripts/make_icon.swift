// Generates the app icon from the corgi sprite.
// Usage: swift Scripts/make_icon.swift HabitQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png


import AppKit

let size = 1024
// Pochi's head (see PixelCorgi in HabitQuest/Corgi.swift), tongue out, chin closed.
let sprite = [
    "..KK......KK.",
    ".KOOK....KOOK",
    ".KOPOK..KOPOK",
    ".KOPPOKKOPPOK",
    "KOOOOOWWOOOOK",
    "KOOKOOWWOOKOK",
    "KOOKOWWWWOKOK",
    "KOOWWWNNWWWOK",
    ".KOWWWPPWWWK.",
    "..KWWWWPWWK..",
    "...KKKKKKK...",
]
func rgb(_ r: Double, _ g: Double, _ b: Double) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: 1) }
func hex(_ h: UInt32) -> CGColor {
    rgb(Double((h >> 16) & 0xFF) / 255, Double((h >> 8) & 0xFF) / 255, Double(h & 0xFF) / 255)
}
let colors: [Character: CGColor] = [
    "K": hex(0x2B1D16), "O": hex(0xE8913A), "W": hex(0xFFF6EA), "P": hex(0xF4A3A3), "N": hex(0x120C09),
]

let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// Flip so y goes down like the sprite rows.
ctx.translateBy(x: 0, y: CGFloat(size)); ctx.scaleBy(x: 1, y: -1)

// App's red → orange gradient, with a soft light behind the head.
let bg = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                    colors: [rgb(0.55, 0.12, 0.24), rgb(0.95, 0.50, 0.30)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size, y: size), options: [])
let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                      colors: [CGColor(red: 1, green: 0.85, blue: 0.6, alpha: 0.35),
                               CGColor(red: 1, green: 0.85, blue: 0.6, alpha: 0)] as CFArray,
                      locations: [0, 1])!
let center = CGPoint(x: 512, y: 500)
ctx.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: 480, options: [])

let px = 64
let x0 = (size - sprite[0].count * px) / 2
let y0 = (size - sprite.count * px) / 2 + 24
for (r, line) in sprite.enumerated() {
    for (c, ch) in line.enumerated() {
        guard let color = colors[ch] else { continue }
        ctx.setFillColor(color)
        ctx.fill(CGRect(x: x0 + c * px, y: y0 + r * px, width: px, height: px))
    }
}

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
