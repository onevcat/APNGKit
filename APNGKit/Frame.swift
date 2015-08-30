//
//  Frame.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

struct Frame {
    
    var image: UIImage?
    
    var bytes: UnsafeMutablePointer<UInt8>
    
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
    let bytesInRow: Int
    
    var duration: NSTimeInterval = 0
    var hidden: Bool = false
    
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
    
    mutating func updateCGImageRef(width: Int, height: Int, bits: Int, scale: CGFloat) {
        
        let provider = CGDataProviderCreateWithData(nil, bytes, length, nil)
        
        if let imageRef = CGImageCreate(width, height, bits, bits * 4, bytesInRow, CGColorSpaceCreateDeviceRGB(),
                        [CGBitmapInfo.ByteOrderDefault, CGBitmapInfo(rawValue: CGImageAlphaInfo.Last.rawValue)],
                        provider, nil, false, .RenderingIntentDefault)
        {
            image = UIImage(CGImage: imageRef, scale: scale, orientation: .Up)
        }
    }
}

extension Frame: CustomStringConvertible {
    var description: String {
        return "<Frame: \(self.bytes)))> duration: \(self.duration), length: \(length)"
    }
}

extension Frame: CustomDebugStringConvertible {

    var data: NSData? {
        if let image = image {
           return UIImagePNGRepresentation(image)
        }
        return nil
    }
    
    var debugDescription: String {
        return "\(description)\ndata: \(data)"
    }
}
