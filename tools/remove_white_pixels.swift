import Foundation
import ImageIO
import CoreGraphics

let args = CommandLine.arguments
if args.count < 3 { exit(1) }
guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(2) }
let width = image.width
let height = image.height
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bytesPerRow = width * 4
var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: info.rawValue) else { exit(3) }
context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
for i in stride(from: 0, to: pixels.count, by: 4) {
    let r = Int(pixels[i]), g = Int(pixels[i + 1]), b = Int(pixels[i + 2])
    let spread = max(r, max(g, b)) - min(r, min(g, b))
    if r >= 238 && g >= 238 && b >= 238 && spread <= 12 { pixels[i + 3] = 0 }
}
guard let outputContext = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: info.rawValue), let output = outputContext.makeImage(), let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, "public.png" as CFString, 1, nil) else { exit(4) }
CGImageDestinationAddImage(destination, output, nil)
CGImageDestinationFinalize(destination)
