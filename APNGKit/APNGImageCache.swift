//
//  APNGImageCache.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/30.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

class APNGCache {
    
    private static let defaultCacheInstance = APNGCache()
    
    class var defaultCache: APNGCache {
        return defaultCacheInstance
    }
    
    let cacheObject = NSCache()
    
    init() {
        cacheObject.totalCostLimit = 0
        cacheObject.name = "com.onevcat.APNGKit.cache"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearMemoryCache", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearMemoryCache", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setImage(image: APNGImage, forKey key: String) {
        cacheObject.setObject(image, forKey: key, cost: image.cost)
    }
    
    func removeImageForKey(key: String) {
        cacheObject.removeObjectForKey(key)
    }
    
    func imageForKey(key: String) -> APNGImage? {
        return cacheObject.objectForKey(key) as? APNGImage
    }
    
    @objc func clearMemoryCache() {
        cacheObject.removeAllObjects()
    }
}

extension APNGImage {
    var cost: Int {
        var s = 0
        for f in frames {
            if let image = f.image {
                s += Int(image.size.height * image.size.width * image.scale * image.scale * CGFloat(self.bitDepth))
            }
        }
        return s
    }
}