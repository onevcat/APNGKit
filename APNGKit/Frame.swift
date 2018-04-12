//
//  Frame.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/27.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(macOS)
    import Cocoa
#else
    import UIKit
#endif

/**
*  Represents a frame in an APNG file. 
*  It contains a whole IDAT chunk data for a PNG image.
*/
class Frame {
    
    static var allocCount = 0
    static var deallocCount = 0
    
    private var width: Int = 0
    private var height: Int = 0
    private var bits: Int = 0
    private var scale: CGFloat = 1.0
    private var blend = false
    
    private var cleaned = false
    
    var image: CocoaImage? {
        let unusedCallback: CGDataProviderReleaseDataCallback = { optionalPointer, pointer, valueInt in }
        guard let provider = CGDataProvider(dataInfo: nil, data: bytes, size: length, releaseData: unusedCallback) else {
            return nil
        }
        
        if let imageRef = CGImage(width: width, height: height, bitsPerComponent: bits, bitsPerPixel: bits * 4, bytesPerRow: bytesInRow, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: [CGBitmapInfo.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)],
                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        {
            #if os(macOS)
                return NSImage(cgImage: imageRef, size: NSSize(width: width, height: height))
            #else
                return UIImage(cgImage: imageRef, scale: scale, orientation: .up)
            #endif
        }
        return nil
    }
    
    /// Data chunk.
    var bytes: UnsafeMutablePointer<UInt8>
    
    /// An array of raw data row pointer. A decoder should fill this area with image raw data.
    lazy var byteRows: Array<UnsafeMutableRawPointer> = {
        var array = Array<UnsafeMutableRawPointer>()
        
        let height = self.length / self.bytesInRow
        for i in 0 ..< height {
            let pointer = self.bytes.advanced(by: i * self.bytesInRow)
            array.append(pointer)
        }
        return array
    }()
    
    let length: Int
    
    /// How many bytes in a row. Regularly it is width * (bitDepth / 2)
    let bytesInRow: Int
    
    var duration: TimeInterval = 0
    
    init(length: UInt32, bytesInRow: UInt32) {
        self.length = Int(length)
        self.bytesInRow = Int(bytesInRow)
        
        self.bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: self.length)
        self.bytes.initialize(to: 0)
        memset(self.bytes, 0, self.length)
    }
    
    func clean() {
        cleaned = true
        bytes.deinitialize(count: length)
        
        #if swift(>=4.1)
        bytes.deallocate()
        #else
        bytes.deallocate(capacity: length)
        #endif
    }
    
    func updateCGImageRef(_ width: Int, height: Int, bits: Int, scale: CGFloat, blend: Bool) {
        self.width = width
        self.height = height
        self.bits = bits
        self.scale = scale
        self.blend = blend
    }
}

extension Frame: CustomStringConvertible {
    var description: String {
        return "<Frame: \(self.bytes)))> duration: \(self.duration), length: \(length)"
    }
}

extension Frame: CustomDebugStringConvertible {

    var data: Data? {
        if let image = image {
            #if os(iOS) || os(watchOS) || os(tvOS)
                return UIImagePNGRepresentation(image)
            #elseif os(OSX)
                return image.tiffRepresentation
            #endif
        }
        return nil
    }
    
    var debugDescription: String {
        return "\(description)\ndata: \(String(describing: data))"
    }
}
