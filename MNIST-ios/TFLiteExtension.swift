//
//  TFLiteExtension.swift
//  MNIST-ios
//
//  Created by yanadoo on 7/24/25.
//

import UIKit
import CoreGraphics

extension UIImage {
    public func scaledData(with size: CGSize) -> Data? {
        guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let width = Int(size.width)
        let height = Int(size.height)
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: cgImage.bitsPerComponent,
                                      bytesPerRow: width*1,
                                      space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: bitmapInfo.rawValue) else { return nil }
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let scaleBytes = context.makeImage()?.dataProvider?.data as Data? else { return nil }
        let scaledFloats = scaleBytes.map { Float($0) / Constant.maxRGBValue }
        
        return Data(copyBufferOf: scaledFloats)
    }
}

extension Data {
    init<T>(copyBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }
    
    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count / MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes{ copyBytes(to: $0) }
        return array
    }
}

private enum Constant {
    static let maxRGBValue: Float32 = 255.0
}
