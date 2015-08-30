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
    var bitDepth: Int = 8
    
    init(frames: [Frame], size: CGSize) {
        self.frames = frames
        self.size = size
    }
    
    init(apng: APNGImage) {
        
        self.bitDepth = apng.bitDepth
        self.size = apng.size
        
        var frames = [Frame]()
        for f in apng.frames {
            var frame = Frame(length: UInt32(f.length), bytesInRow: UInt32(f.bytesInRow))
            memcpy(frame.bytes, f.bytes, f.length)
            frame.duration = f.duration
            frame.hidden = f.hidden
            
            frame.updateCGImageRef(Int(apng.size.width), height: Int(apng.size.height), bits: apng.bitDepth)

            frames.append(frame)
        }
        self.frames = frames
    }
    
    deinit {
        for f in frames {
            f.clean()
        }
    }
}

extension APNGImage {
    static func cacheImage(image: APNGImage, withName: String) {
        
    }
}

extension APNGImage {
    public convenience init?(data: NSData) {
        self.init(data: data, scale: 1)
    }
    
    public convenience init?(named imageName: String) {
        if let path = imageName.apng_filePathByCheckingNameExisting() {
            self.init(contentsOfFile:path, saveToCache: true)
        } else {
            return nil
        }
    }
    
    public convenience init?(contentsOfFile path: String) {
        self.init(contentsOfFile:path, saveToCache: false)
    }
    
    convenience init?(contentsOfFile path: String, saveToCache: Bool) {

        if let apng = APNGCache.defaultCache.imageForKey(path) { // Found in the cache
            print("From cache")
            self.init(apng: apng)
        } else {
            if let data = NSData(contentsOfFile: path) {
                self.init(data: data)
                APNGCache.defaultCache.setImage(self, forKey: path)
            } else {
                return nil
            }
        }
    }
    
    convenience init?(data: NSData, scale: Int) {
        var disassembler = Disassembler(data: data)
        do {
            let (frames, size, repeatCount, bitDepth) = try disassembler.decodeToElements(scale)
            self.init(frames: frames, size: size)
            self.repeatCount = repeatCount
            self.bitDepth = bitDepth
        } catch _ {
            return nil
        }
    }
}

extension APNGImage: CustomStringConvertible {
    public var description: String {
        var s = "<APNGImage: \(unsafeAddressOf(self))> size: \(size), frameCount: \(frames.count), repeatCount: \(repeatCount)\n"
        s += "["
        for f in frames {
            s += "\(f)\n"
        }
        s += "]"
        return s
    }
}

extension String {
    func apng_filePathByCheckingNameExisting() -> String? {
        let name = self as NSString
        let fileExtension = name.pathExtension
        let fileName = name.stringByDeletingPathExtension
        
        // If the name is suffixed by 2x or 3x, we think users want to the specified version
        if fileName.hasSuffix("@2x") || fileName.hasSuffix("@3x") {
            let path = NSBundle.mainBundle().pathForResource(fileName, ofType: fileExtension)
            return path
        }
        
        // Else, user is passing a common name. We will try to find the version match current scale first
        var path: String? = nil
        let scale = Int(UIScreen.mainScreen().scale)
        
        path = NSBundle.mainBundle().pathForResource("\(fileName)@\(scale)x", ofType: fileExtension)
        
        if path != nil {
            return path
        }
        
        // Matched scaled version not found, use the 1x version
        return NSBundle.mainBundle().pathForResource(fileName, ofType: fileExtension)
    }
}

