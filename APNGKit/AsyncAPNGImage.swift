//
//  APNGImage.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/27.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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

/// Represents a decoded APNG image.
/// You can use instance of this class to get image information or display it on screen with `APNGImageView`.
/// `APNGImage` can hold an APNG image or a regular PNG image. If latter, there will be only one frame in the image.
public class AsyncAPNGImage: NSObject, APNGImageProtocol { // For ObjC compatibility
    public func frameAt(index: Int) -> SharedFrame {
        return frameList.waitForFrame(index)
    }
    
    public var frameCount: Int {
        return frameList.frameCount
    }
    
    /// Size of the image in point. The scale factor is considered.
    public var size: CGSize {
        return CGSizeMake(internalSize.width / scale, internalSize.height / scale)
    }
    
    /// Scale of the image.
    public let scale: CGFloat
    
    /// Number of frames of the APNG to buffer
    public let numFramesToBuffer: Int
    
    /// Repeat count of animation of the APNG image.
    /// It is read from APNG data. However, you can change it to modify the loop behaviors.
    /// Set this to `RepeatForever` will make the animation loops forever.
    public var repeatCount: Int
    
    public let firstFrameHidden: Bool
    var frameList: Disassembler.AsyncFrameList
    var bitDepth: Int
    
    // Strong refrence to another APNG to hold data if this image object is retrieved from cache
    // The frames data will not be changed once a frame is setup.
    // So we could share the bytes in it between two "same" APNG image objects.
    private let internalSize: CGSize // size in pixel
    
    static var searchBundle: NSBundle = NSBundle.mainBundle()
    
    init(frameList: Disassembler.AsyncFrameList, size: CGSize, scale: CGFloat, bitDepth: Int, repeatCount: Int, firstFrameHidden hidden: Bool, numFramesToBuffer: Int) {
        self.frameList = frameList
        self.internalSize = size
        self.scale = scale
        self.bitDepth = bitDepth
        self.repeatCount = repeatCount
        self.firstFrameHidden = hidden
        self.numFramesToBuffer = numFramesToBuffer
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
     
     - returns: The image object for the specified file, or nil if the method could not find the specified image.
     
     */
    public convenience init?(named imageName: String, numFramesToBuffer: Int = 5) {
        if let path = imageName.apng_filePathByCheckingNameExistingInBundle(APNGImage.searchBundle) {
            self.init(contentsOfFile:path, numFramesToBuffer: numFramesToBuffer)
        } else {
            return nil
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
    public convenience init?(data: NSData, numFramesToBuffer: Int = 5) {
        self.init(data: data, scale: 1, numFramesToBuffer: numFramesToBuffer)
    }
    
    /**
     Creates and returns an image object that uses the specified image data and scale factor.
     
     - note: This method does not cache the image object.
     
     - parameter data:  The image data of APNG. This can be data from a file or data you get from network.
     - parameter scale: The scale factor to use when interpreting the image data. Specifying a scale factor of 1.0 results in
     an image whose size matches the pixel-based dimensions of the image. Applying a different scale factor
     changes the size of the image as reported by the size property.
     
     - returns: A new image object for the specified data, or nil if the method could not initialize the image from the specified data.
     */
    public convenience init?(data: NSData, scale: CGFloat, numFramesToBuffer: Int = 5) {
        let disassembler = Disassembler(data: data)
        do {
            let (frameList, size, repeatCount, bitDepth, firstFrameHidden) = try disassembler.decodeToElementsAsync(scale, numFramesToBuffer: numFramesToBuffer)
            self.init(frameList: frameList, size: size, scale: scale, bitDepth: bitDepth, repeatCount: repeatCount, firstFrameHidden: firstFrameHidden, numFramesToBuffer: numFramesToBuffer)
        } catch _ {
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
     - parameter saveToCache: Should the result image saved to APNGKit caches. Default is false.
     
     - returns: A new image object for the specified file, or nil if the method could not initialize the image from the specified file.
     */
    public convenience init?(contentsOfFile path: String, numFramesToBuffer: Int = 5) {
        
        if let data = NSData(contentsOfFile: path) {
            let fileName = (path as NSString).stringByDeletingPathExtension
            
            var scale: CGFloat = 1
            if fileName.hasSuffix("@2x") {
                scale = 2
            }
            if fileName.hasSuffix("@3x") {
                scale = 3
            }
            
            self.init(data: data, scale: scale, numFramesToBuffer: numFramesToBuffer)
        } else {
            return nil
        }
    }
    
    deinit {
        frameList.terminate()
    }
}

extension AsyncAPNGImage {
    override public var description: String {
        var s = "<AsyncAPNGImage: \(unsafeAddressOf(self))> size: \(size), frameCount: \(frameList.frameCount), repeatCount: \(repeatCount)\n"
        s += "["
        s += "]"
        return s
    }
}
