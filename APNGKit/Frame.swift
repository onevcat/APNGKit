//
//  Frame.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/27.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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

import UIKit

public class SharedFrame: UIImage {
    static var allocatedCount: Int = 0
    static var deallocatedCount: Int = 0
    
    init(bytes: UnsafeMutablePointer<UInt8>, length: Int, duration: NSTimeInterval) {
        self.bytes = bytes
        self.length = length
        self._duration = duration
        super.init()
    }
    
    init(CGImage: CGImageRef, scale: CGFloat, bytes: UnsafeMutablePointer<UInt8>, length: Int, duration: NSTimeInterval) {
        self.bytes = bytes
        self.length = length
        self._duration = duration
        super.init(CGImage: CGImage, scale: scale, orientation: .Up)
    }

    required convenience public init(imageLiteral name: String) {
        fatalError("init(imageLiteral:) has not been implemented")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let length: Int
    let bytes: UnsafeMutablePointer<UInt8>?
    let _duration: NSTimeInterval
    public override var duration: NSTimeInterval {
        return _duration
    }
    
    deinit {
        bytes?.destroy(length)
        bytes?.dealloc(length)
    }
}

/**
*  Represents a frame in an APNG file.
*  It contains a whole IDAT chunk data for a PNG image.
*/
struct Frame {
    /// Data chunk.
    var bytes: UnsafeMutablePointer<UInt8>
    
    /// An array of raw data row pointer. A decoder should fill this area with image raw data.
    lazy var byteRows: Array<UnsafeMutablePointer<UInt8>> = {
        var array = Array<UnsafeMutablePointer<UInt8>>()
        
        let height = self.length / self.bytesInRow
        for i in 0 ..< height {
            let pointer = self.bytes.advancedBy(i * self.bytesInRow)
            array.append(pointer)
        }
        return array
    }()
    
    let length: Int
    
    /// How many bytes in a row. Regularly it is width * (bitDepth / 2)
    let bytesInRow: Int
    
    var duration: NSTimeInterval = 0
    
    init(length: UInt32, bytesInRow: UInt32) {
        self.length = Int(length)
        self.bytesInRow = Int(bytesInRow)
        
        self.bytes = UnsafeMutablePointer<UInt8>.alloc(self.length)
        self.bytes.initialize(0)
        memset(self.bytes, 0, self.length)
    }
    
    func clean() {
        bytes.destroy(length)
        bytes.dealloc(length)
    }
    
    var sharedFrame: SharedFrame?
    mutating func createSharedFrame(width: Int, height: Int, bits: Int, scale: CGFloat) -> SharedFrame {
        let provider = CGDataProviderCreateWithData(nil, bytes, length, nil)
        
        if let imageRef = CGImageCreate(width, height, bits, bits * 4, bytesInRow, CGColorSpaceCreateDeviceRGB(),
            [CGBitmapInfo.ByteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.Last.rawValue)],
            provider, nil, false, .RenderingIntentDefault)
        {
            sharedFrame = SharedFrame.init(CGImage: imageRef, scale: scale, bytes: bytes, length: length, duration: duration)
            return sharedFrame!
        } else {
            sharedFrame = SharedFrame.init(bytes: bytes, length: length, duration: duration)
            return sharedFrame!
        }
    }
}

extension Frame: CustomStringConvertible {
    var description: String {
        return "<Frame: \(self.bytes)))> duration: \(self.duration), length: \(length)"
    }
}
