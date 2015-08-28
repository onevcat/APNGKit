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
    var frames: [Frame]
    
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