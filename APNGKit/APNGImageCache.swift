//
//  APNGImageCache.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/30.
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

/// Cache for APNGKit. It will hold apng images initialized from specified init methods.
/// If the same file is requested later, APNGKit will look it up in this cache first to improve performance.
open class APNGCache {
    
    fileprivate static let defaultCacheInstance = APNGCache()
    
    /// The default cache object. It is used internal in APNGKit.
    /// You should always use this object to interact with APNG cache as well.
    open class var defaultCache: APNGCache {
        return defaultCacheInstance
    }
    
    let cacheObject = NSCache<NSString, APNGImage>()
    
    init() {
        // Limit the cache to prevent memory warning as possible.
        // The cache will be invalidated once a memory warning received, 
        // so we need to keep cache in limitation and try to not trigger the memory warning.
        // See clearMemoryCache() for more.
        cacheObject.totalCostLimit = 100 * 1024 * 1024 //100 MB
        cacheObject.countLimit = 15
        
        cacheObject.name = "com.onevcat.APNGKit.cache"
        #if !os(OSX)
            NotificationCenter.default.addObserver(self, selector: #selector(APNGCache.clearMemoryCache),
                                                   name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(APNGCache.clearMemoryCache),
                                                   name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        #endif
    }
    
    deinit {
        #if !os(OSX)
            NotificationCenter.default.removeObserver(self)
        #endif
    }
    
    /**
    Cache an APNG image with specified key.
    
    - parameter image: The image should be cached.
    - parameter key:   The key of that image
    */
    open func setImage(_ image: APNGImage, forKey key: String) {
        cacheObject.setObject(image, forKey: key as NSString, cost: image.cost)
    }
    
    /**
    Remove an APNG image from cache with specified key.
    
    - parameter key: The key of that image
    */
    open func removeImageForKey(_ key: String) {
        cacheObject.removeObject(forKey: key as NSString)
    }
    
    func imageForKey(_ key: String) -> APNGImage? {
        return cacheObject.object(forKey: key as NSString)
    }
    
    /**
    Clear the memory cache.
    - note: Generally speaking you could just use APNGKit without worrying the memory and cache.
            The cached images will be removed when a memory warning is received or your app is switched to background.
            However, there is a chance that you want to do an operation requiring huge amount of memory, which may cause
            your app OOM directly without receiving a memory warning. In this situation, you could call this method first 
            to release the APNG cache for your memory costing operation.
    */
    @objc open func clearMemoryCache() {
        // The cache will not work once it receives a memory warning from iOS 8.
        // It seems an intended behaviours to reduce memory pressure.
        // See http://stackoverflow.com/questions/27289360/nscache-objectforkey-always-return-nil-after-memory-warning-on-ios-8
        // The solution in that post does not work on iOS 9. I guess just follow the system behavior would be good.
        cacheObject.removeAllObjects()
    }
}

extension APNGImage {
    var cost: Int {
        guard let frames = frames else {
            return 0
        }
        var s = 0
        for f in frames {
            if let image = f.image {
                // Totol bytes
                #if os(macOS)
                    s += Int(image.size.height * image.size.width * CGFloat(self.bitDepth))
                #else
                    s += Int(image.size.height * image.size.width * image.scale * image.scale * CGFloat(self.bitDepth))
                #endif
            }
        }
        return s
    }
}
