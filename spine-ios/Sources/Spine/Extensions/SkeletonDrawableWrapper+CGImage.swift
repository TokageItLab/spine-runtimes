import Foundation
import UIKit
import CoreGraphics

public extension SkeletonDrawableWrapper {
    
    /// Render the ``Skeleton`` to a `CGImage`
    ///
    /// Parameters:
    ///     - size: The size of the `CGImage` that should be rendered.
    ///     - backgroundColor: the background color of the image
    ///     - scaleFactor: The scale factor. Set this to `UIScreen.main.scale` if you want to show the image in a view
    func renderToImage(size: CGSize, backgroundColor: UIColor, scaleFactor: CGFloat = 1) throws -> CGImage? {
        let spineView = SpineUIView(
            controller: SpineController(disposeDrawableOnDeInit: false), // Doesn't own the drawable
            backgroundColor: backgroundColor
        )
        spineView.frame = CGRect(origin: .zero, size: size)
        spineView.isPaused = false
        spineView.enableSetNeedsDisplay = false
        spineView.framebufferOnly = false
        spineView.contentScaleFactor = scaleFactor
        
        try spineView.load(drawable: self)
        spineView.renderer?.waitUntilCompleted = true
        
        spineView.delegate?.draw(in: spineView)
        
        guard let texture = spineView.currentDrawable?.texture else {
            throw "Could not read texture."
        }
        let width = texture.width
        let height = texture.height
        let rowBytes = width * 4
        let data = UnsafeMutableRawPointer.allocate(byteCount: rowBytes * height, alignment: MemoryLayout<UInt8>.alignment)
        defer {
            data.deallocate()
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(data, bytesPerRow: rowBytes, from: region, mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue
        ).union(.byteOrder32Little)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
              let cgImage = context.makeImage() else {
                throw "Could not create image."
        }
        return cgImage
    }
}
