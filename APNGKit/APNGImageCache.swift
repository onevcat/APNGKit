//
//  APNGImageCache.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/30.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

/// Cache for APNGKit. It will hold apng images initialized from specified init methods.
/// If the same file is requested later, APNGKit will look it up in this cache first to improve performance.
public class APNGCache {
    
    private static let defaultCacheInstance = APNGCache()
    
    /// The default cache object. It is used internal in APNGKit.
    /// You should always use this object to interact with APNG cache as well.
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
    
    /**
    Cache an APNG image with specified key.
    
    - parameter image: The image should be cached.
    - parameter key:   The key of that image
    */
    public func setImage(image: APNGImage, forKey key: String) {
        cacheObject.setObject(image, forKey: key, cost: image.cost)
    }
    
    /**
    Remove an APNG image from cache with specified key.
    
    - parameter key: The key of that image
    */
    public func removeImageForKey(key: String) {
        cacheObject.removeObjectForKey(key)
    }
    
    func imageForKey(key: String) -> APNGImage? {
        return cacheObject.objectForKey(key) as? APNGImage
    }
    
    /**
    Clear the memory cache.
    - note: Generally speaking you could just use APNGKit without worrying the memory and cache.
            The cached images will be removed when a memory warning is received or your app is switched to background.
            However, there is a chance that you want to do an operation requiring huge amount of memory, which may cause
            your app OOM directly without receiving a memory warning. In this situation, you could call this method first 
            to release the APNG cache for your memory costing operation.
    */
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