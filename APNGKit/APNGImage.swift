//
//  APNGImage.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/27.
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

import UIKit

/// APNG animation should repeat forever.
public let RepeatForever = -1

/// Represents a decoded APNG image. 
/// You can use instance of this class to get image information or display it on screen with `APNGImageView`.
/// `APNGImage` can hold an APNG image or a regular PNG image. If latter, there will be only one frame in the image.
open class APNGImage: NSObject { // For ObjC compatibility
    
    /// Total duration of the animation. If progressive loading is used, this property returns 0.0.
    open var duration: TimeInterval {
        return frames?.reduce(0.0) {
            $0 + $1.duration
        } ?? 0.0
    }
    
    /// Size of the image in point. The scale factor is considered.
    open var size: CGSize {
        return CGSize(width: internalSize.width / scale, height: internalSize.height / scale)
    }
    
    /// Scale of the image.
    open let scale: CGFloat
    
    /// Repeat count of animation of the APNG image.
    /// It is read from APNG data. However, you can change it to modify the loop behaviors.
    /// Set this to `RepeatForever` will make the animation loops forever.
    open var repeatCount: Int
    
    let firstFrameHidden: Bool
    let bitDepth: Int
    let frameCount: Int
    
    fileprivate(set) var frames: [Frame]?
    
    // Keep a frame strong reference so it will not get released when using Disassembler
    var currentFrame: Frame?
    fileprivate(set) var disassembler: Disassembler?
    
    func reset() {
        if let disassembler = disassembler {
            disassembler.clean()
        }
    }
    
    func next(currentIndex: Int) -> Frame {

        if let frames = frames {
            
            guard !frames.isEmpty else {
                fatalError("Empty frames.")
            }
            
            if currentIndex >= frames.count {
                return frames[0]
            } else {
                return frames[currentIndex]
            }
        } else if let disassembler = disassembler {
            var frame = disassembler.next()
            // If the last frame encountered, the first `next` call will return `nil`
            // We should restart the iterator to get the first frame.
            if frame == nil {
                frame = disassembler.next()
            }
            
            currentFrame?.clean()
            currentFrame = frame
            
            return frame!
        } else {
            fatalError("Neither frames or disassembler exist.")
        }
    }
    
    // Strong refrence to another APNG to hold data if this image object is retrieved from cache
    // The frames data will not be changed once a frame is setup.
    // So we could share the bytes in it between two "same" APNG image objects.
    fileprivate let dataOwner: APNGImage?
    fileprivate let internalSize: CGSize // size in pixel
    
    static var searchBundle: Bundle = Bundle.main

    init(scale: CGFloat, meta: APNGMeta) {
        let size = CGSize(width: Int(meta.width), height: Int(meta.height))
        self.internalSize = size
        self.scale = scale
        self.bitDepth = Int(meta.bitDepth)
        self.repeatCount = Int(meta.playCount) - 1
        self.firstFrameHidden = meta.firstFrameHidden
        self.frameCount = Int(meta.frameCount)
        dataOwner = nil
    }
    
    convenience init(frames: [Frame], scale: CGFloat, meta: APNGMeta) {
        self.init(scale: scale, meta: meta)
        self.frames = frames
        self.disassembler = nil
    }
    
    convenience init(disassembler: Disassembler, scale: CGFloat, meta: APNGMeta) {
        self.init(scale: scale, meta: meta)
        self.disassembler = disassembler
        self.frames = nil
    }
    
    init(apng: APNGImage) {
        // The image init from this method will share the same data trunk with the other apng obj
        if apng.frames != nil {
            dataOwner = apng
            frames = apng.frames
        } else {
            dataOwner = nil
            frames = nil
        }
        
        if apng.disassembler != nil {
            disassembler = Disassembler(data: apng.disassembler!.originalData, scale: apng.scale)
        } else {
            disassembler = nil
        }
        
        self.bitDepth = apng.bitDepth
        self.internalSize = apng.internalSize
        self.scale = apng.scale
        self.repeatCount = apng.repeatCount
        self.firstFrameHidden = apng.firstFrameHidden
        self.frameCount = apng.frameCount
    }
    
    /**
     Returns the image object associated with the specified filename.
     This method looks in the APNGKit caches for an image object with the specified name and returns a new object with same data if it exists.
     If a matching image object is not already in the cache, this method locates and loads the image data from disk, and then returns the resulting object.
     You can not assume that this method is thread safe. If the screen has a scale larger than 1.0, this method first searches for an image file with the
     same filename with a responding suffix (@2x or @3x) appended to it. For example, if the file’s name is button, it first searches for button@2x.
     If it finds a 2x, it loads that image and sets the scale property of the returned UIImage object to 2.0. Otherwise, it loads the unmodified filename
     and sets the scale property to 1.0.

     - note: This method will cache the result image in APNGKit cache system to improve performance.
             Images in Asset Category is not supported, you can only load files from the app's main bundle.
    
     - note: The image file should not be compressed by Xcode. By default, Xcode will compress PNG files in the app bundle by using a private pngcrush
             version, which will opt-out all frames data except the first frame from the APNG image. You should change your APNG file extension to "apng"
             (or anything besides "png") or just turn off the PNG compression in Xcode build settings to avoid this.
    
     - parameter imageName: The name of the file. If this is the first time the image is being loaded,
                            the method looks for an image with the specified name in the application’s main bundle.
     - parameter loadAll:   When set to false, only `framePreloadCount` frames will be loaded. This could free up memory
                            that are not current displayed, but take more performance to load the needed frames when they
                            are to be displayed. Otherwise, all frames will be loaded. Default is `true`.

     - returns: The image object for the specified file, or nil if the method could not find the specified image.
    
    */
    public convenience init?(named imageName: String, loadAll: Bool = true) {
        if let path = imageName.apng_filePathByCheckingNameExistingInBundle(APNGImage.searchBundle) {
            self.init(contentsOfFile:path, saveToCache: true, loadAll: loadAll)
        } else {
            return nil
        }
    }

    /**
     Creates and returns an image object by loading the image data from the file at the specified path.
     
     - note: This method does not cache the image object by default.
     But it is recommended to enable the cache to improve performance,
     especially if you have multiple same APNG image to show at the same time.
     
     - note: The image file should not be compressed by Xcode. By default, Xcode will compress PNG files in the app bundle by using a private pngcrush
     version, which will opt-out all frames data except the first frame from the APNG image. You should change your APNG file extension to "apng"
     (or anything besides "png") or just turn off the PNG compression in Xcode build settings to avoid this.
     
     - parameter path:        The path to the file.
     - parameter saveToCache: Should the result image saved to APNGKit memory caches. Default is false. Only works when `loadAll` is `true`.
     - parameter loadAll:     When set to false, only `framePreloadCount` frames will be loaded. This could free up memory
     that are not current displayed, but take more performance to load the needed frames when they
     are to be displayed. Otherwise, all frames will be loaded. Default is `true`.
     
     - returns: A new image object for the specified file, or nil if the method could not initialize the image from the specified file.
     */
    public convenience init?(contentsOfFile path: String, saveToCache: Bool = false, loadAll: Bool = true) {
        
        if let apng = APNGCache.defaultCache.imageForKey(path) { // Found in the cache
            self.init(apng: apng)
        } else {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let fileName = (path as NSString).deletingPathExtension
                
                var scale: CGFloat = 1
                if fileName.hasSuffix("@2x") {
                    scale = 2
                }
                if fileName.hasSuffix("@3x") {
                    scale = 3
                }
                
                self.init(data: data, scale: scale, loadAll: loadAll)
                
                if saveToCache && loadAll {
                    APNGCache.defaultCache.setImage(self, forKey: path)
                }
            } else {
                return nil
            }
        }
    }
    
    /**
     Creates and returns an image object that uses the specified image data.
     The scale factor will always be 1.0 if you create the image from data with this method.
     If you need an image at a specified scale, use init methods from disk or -initWithData:scale: instead
     
     - note: This method does not cache the image object.
     
     - parameter data: The image data of APNG. This can be data from a file or data you get from network.
     
     - returns: A new image object for the specified data, or nil if the method could not initialize the image from the specified data.
     
     */
    public convenience init?(data: Data, loadAll: Bool = true) {
        self.init(data: data, scale: 1, loadAll: loadAll)
    }
    
    /**
     Creates and returns an image object that uses the specified image data and scale factor.
    
     - note: This method does not cache the image object.

     - parameter data:    The image data of APNG. This can be data from a file or data you get from network.
     - parameter scale:   The scale factor to use when interpreting the image data. Specifying a scale factor of 1.0 results in
                          an image whose size matches the pixel-based dimensions of the image. Applying a different scale factor
                          changes the size of the image as reported by the size property.
     - parameter loadAll: When set to false, only `framePreloadCount` frames will be loaded. This could free up memory
                          that are not current displayed, but take more performance to load the needed frames when they
                          are to be displayed. Otherwise, all frames will be loaded. Default is `true`.
    
     - returns: A new image object for the specified data, or nil if the method could not initialize the image from the specified data.
    */
    public convenience init?(data: Data, scale: CGFloat, loadAll: Bool = true) {
        let disassembler = Disassembler(data: data)
        
        if loadAll {
            do {
                let (frames, meta) = try disassembler.decodeToElements(scale)
                self.init(frames: frames, scale: scale, meta: meta)
            } catch {
                return nil
            }
        } else {
            do {
                let meta = try disassembler.decodeMeta()
                self.init(disassembler: disassembler, scale: scale, meta: meta)
            } catch {
                return nil
            }
        }
    }
    
    deinit {
        if dataOwner == nil { // Only clean when self owns the data
            if let frames = frames {
                for f in frames {
                    f.clean()
                }
            }
        }
    }
}

extension APNGImage {
    override open var description: String {
        guard let frames = frames else {
            return ""
        }
        var s = "<APNGImage: \(Unmanaged.passUnretained(self).toOpaque())> size: \(size), frameCount: \(frames.count), repeatCount: \(repeatCount)\n"
        s += "["
        for f in frames {
            s += "\(f)\n"
        }
        s += "]"
        return s
    }
}

extension String {
    func apng_filePathByCheckingNameExistingInBundle(_ bundle: Bundle) -> String? {
        let name = self as NSString
        let fileExtension = name.pathExtension
        let fileName = name.deletingPathExtension
        
        // If the name is suffixed by 2x or 3x, we think users want to the specified version
        if fileName.hasSuffix("@2x") || fileName.hasSuffix("@3x") {
            var path: String?
            path = bundle.path(forResource: fileName, ofType: fileExtension) ??
                   bundle.path(forResource: fileName, ofType: "apng") ??
                   bundle.path(forResource: fileName, ofType: "png")
            return path
        }
        
        // Else, user is passing a common name without known suffix.
        // We will try to find the version match current scale first, then the one with 1 less scale factor.
        var path: String?
        let scales = 1 ... Int(UIScreen.main.scale)
        
        path = scales.reversed().reduce(nil) { (result, scale) -> String? in
            return result ??
                   bundle.path(forResource: "\(fileName)@\(scale)x", ofType: fileExtension) ??
                   bundle.path(forResource: "\(fileName)@\(scale)x", ofType: "apng") ??
                   bundle.path(forResource: "\(fileName)@\(scale)x", ofType: "png")
        }
        
        path = path ??
               bundle.path(forResource: fileName, ofType: fileExtension) ?? // Matched scaled version not found, use the 1x version
               bundle.path(forResource: fileName, ofType: "apng") ??
               bundle.path(forResource: fileName, ofType: "png")
        
        return path
    }
}

