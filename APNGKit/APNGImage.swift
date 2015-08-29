//
//  APNGImage.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

public let RepeatForever = -1

public class APNGImage {
    
    public var repeatCount: Int = RepeatForever
    public var duration: NSTimeInterval {
        return frames.reduce(0.0) {
            $0 + $1.duration
        }
    }

    public let size: CGSize

    let frames: [Frame]
    
    init(frames: [Frame], size: CGSize) {
        self.frames = frames
        self.size = size
    }
    
    deinit {
        for f in frames {
            f.clean()
        }
    }
}

extension APNGImage {
    public convenience init?(data: NSData) {
        var disassembler = Disassembler(data: data)
        do {
            let (frames, size, repeatCount) = try disassembler.decodeToElements()
            self.init(frames: frames, size: size)
            self.repeatCount = repeatCount
        } catch _ {
            return nil
        }
    }

}

extension APNGImage: CustomStringConvertible {
    public var description: String {
        return "<APNGImage> size: \(size), frameCount: \(frames.count), repeatCount: \(repeatCount)"
    }
}

extension APNGImage: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<APNGImage> size: \(size), frameCount: \(frames.count), repeatCount: \(repeatCount)"
    }
}
