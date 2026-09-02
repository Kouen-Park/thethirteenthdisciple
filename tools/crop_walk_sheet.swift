import Foundation
import ImageIO
import CoreGraphics

let args = CommandLine.arguments
if args.count < 3 { exit(1) }
guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: args[1]) as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(2) }
let width = image.width
let height = image.height
let cropHeight = min(1300, height)
let cropY = max(0, (height - cropHeight) / 2)
let cropRect = CGRect(x: 0, y: cropY, width: width, height: cropHeight)
guard let cropped = image.cropping(to: cropRect) else { exit(3) }
guard let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, "public.png" as CFString, 1, nil) else { exit(4) }
CGImageDestinationAddImage(destination, cropped, nil)
CGImageDestinationFinalize(destination)
