//
//  APNGImageView.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/28.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

class APNGImageView: UIView {
    
    var image: APNGImage?
    
    init(image: APNGImage?) {
        self.image = image
        if let image = image {
            super.init(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        } else {
            super.init(frame: CGRectZero)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        image?.frames.first?.image?.drawInRect(rect)
    }
}