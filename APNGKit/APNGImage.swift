//
//  APNGImage.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

class APNGImage {
    let repeatCount: Int
    let frames: [Frame]
    
    init(frames: [Frame], repeatCount: Int) {
        self.frames = frames
        self.repeatCount = repeatCount
    }
    
    deinit {
        for f in frames {
            f.clean()
        }
    }
}

extension APNGImage: CustomStringConvertible {
    var description: String {
        return "<APNGImage> frameCount: \(frames.count)"
    }
}

extension APNGImage: CustomDebugStringConvertible {
    var debugDescription: String {
        return ""
    }
}

