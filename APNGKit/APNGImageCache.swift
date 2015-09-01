//
//  APNGImageCache.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/30.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

public class APNGCache {
    
    private static let defaultCacheInstance = APNGCache()
    
    public class var defaultCache: APNGCache {
        return defaultCacheInstance
    }
    
    let cacheObject = NSCache()
    
    init() {
        cacheObject.totalCostLimit = 0
        cacheObject.name = "com.onevcat.APNGKit.cache"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearMemoryCache",
                                                                   name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "clearMemoryCache",
                                                                   name: UIApplicationDidEnterBackgroundNotification, object: nil)
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
    
    @objc public func clearMemoryCache() {
        // The cache will not work once it receives a memory warning from iOS 8.
        // It seems an intended behaviours to reduce memory pressure.
        // See http://stackoverflow.com/questions/27289360/nscache-objectforkey-always-return-nil-after-memory-warning-on-ios-8
        // The solution in that post does not work on iOS 9. I guess just follow the system behavior would be good.
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