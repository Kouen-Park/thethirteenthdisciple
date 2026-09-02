import Foundation
import ImageIO
import CoreGraphics

let args = CommandLine.arguments
if args.count < 3 { exit(1) }
let inputURL = URL(fileURLWithPath: args[1]) as CFURL
let outputURL = URL(fileURLWithPath: args[2]) as CFURL

guard let source = CGImageSourceCreateWithURL(inputURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(2) }
let width = image.width
let height = image.height
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bytesPerRow = width * 4
var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { exit(3) }
context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

func isCheckerPixel(_ offset: Int) -> Bool {
    let r = Int(pixels[offset])
    let g = Int(pixels[offset + 1])
    let b = Int(pixels[offset + 2])
    let spread = max(r, max(g, b)) - min(r, min(g, b))
    return spread <= 5 && r >= 185 && g >= 185 && b >= 185
}

var visited = [Bool](repeating: false, count: width * height)
var queue: [(Int, Int)] = []
func enqueue(_ x: Int, _ y: Int) {
    if x < 0 || y < 0 || x >= width || y >= height { return }
    let index = y * width + x
    if visited[index] { return }
    let offset = index * 4
    if !isCheckerPixel(offset) { return }
    visited[index] = true
    queue.append((x, y))
}
for x in 0..<width { enqueue(x, 0); enqueue(x, height - 1) }
for y in 0..<height { enqueue(0, y); enqueue(width - 1, y) }
var cursor = 0
while cursor < queue.count {
    let (x, y) = queue[cursor]; cursor += 1
    let offset = (y * width + x) * 4
    pixels[offset + 3] = 0
    enqueue(x - 1, y); enqueue(x + 1, y); enqueue(x, y - 1); enqueue(x, y + 1)
}

guard let outputContext = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
      let outputImage = outputContext.makeImage(),
      let destination = CGImageDestinationCreateWithURL(outputURL, "public.png" as CFString, 1, nil) else { exit(4) }
CGImageDestinationAddImage(destination, outputImage, nil)
CGImageDestinationFinalize(destination)
print("wrote \(args[2])")
