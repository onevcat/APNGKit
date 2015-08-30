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

    public var duration: NSTimeInterval {
        return frames.reduce(0.0) {
            $0 + $1.duration
        }
    }

    private let internalSize: CGSize
    
    public var size: CGSize {
        return CGSizeMake(internalSize.width / scale, internalSize.height / scale)
    }
    
    public let scale: CGFloat
    var frames: [Frame]
    var bitDepth: Int
    public var repeatCount: Int
    
    static var searchBundle: NSBundle = NSBundle.mainBundle()

    init(frames: [Frame], size: CGSize, scale: CGFloat, bitDepth: Int, repeatCount: Int) {
        self.frames = frames
        self.internalSize = size
        self.scale = scale
        self.bitDepth = bitDepth
        self.repeatCount = repeatCount
    }
    
    init(apng: APNGImage) {
        
        self.bitDepth = apng.bitDepth
        self.internalSize = apng.internalSize
        self.scale = apng.scale
        self.repeatCount = apng.repeatCount
        
        var frames = [Frame]()
        for f in apng.frames {
            var frame = Frame(length: UInt32(f.length), bytesInRow: UInt32(f.bytesInRow))
            memcpy(frame.bytes, f.bytes, f.length)
            frame.duration = f.duration
            frame.hidden = f.hidden
            
            frame.updateCGImageRef(Int(apng.internalSize.width), height: Int(apng.internalSize.height), bits: apng.bitDepth, scale: apng.scale)

            frames.append(frame)
        }
        self.frames = frames
    }
    
    public convenience init?(named imageName: String) {
        if let path = imageName.apng_filePathByCheckingNameExistingInBundle(APNGImage.searchBundle) {
            self.init(contentsOfFile:path, saveToCache: true)
        } else {
            return nil
        }
    }
    
    public convenience init?(data: NSData) {
        self.init(data: data, scale: 1)
    }
    
    public convenience init?(contentsOfFile path: String) {
        self.init(contentsOfFile:path, saveToCache: false)
    }
    
    convenience init?(contentsOfFile path: String, saveToCache: Bool) {
        
        if let apng = APNGCache.defaultCache.imageForKey(path) { // Found in the cache
            self.init(apng: apng)
        } else {
            if let data = NSData(contentsOfFile: path) {
                let fileName = (path as NSString).stringByDeletingPathExtension
                
                var scale: CGFloat = 1
                if fileName.hasSuffix("@2x") {
                    scale = 2
                }
                if fileName.hasSuffix("@3x") {
                    scale = 3
                }
                
                self.init(data: data, scale: scale)
                APNGCache.defaultCache.setImage(self, forKey: path)
            } else {
                return nil
            }
        }
    }
    
    convenience init?(data: NSData, scale: CGFloat) {
        var disassembler = Disassembler(data: data)
        do {
            let (frames, size, repeatCount, bitDepth) = try disassembler.decodeToElements(scale)
            self.init(frames: frames, size: size, scale: scale, bitDepth: bitDepth, repeatCount: repeatCount)
        } catch _ {
            return nil
        }
    }
    
    deinit {
        for f in frames {
            f.clean()
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
    func apng_filePathByCheckingNameExistingInBundle(bundle: NSBundle) -> String? {
        let name = self as NSString
        let fileExtension = name.pathExtension
        let fileName = name.stringByDeletingPathExtension
        
        // If the name is suffixed by 2x or 3x, we think users want to the specified version
        if fileName.hasSuffix("@2x") || fileName.hasSuffix("@3x") {
            var path: String?
            path = bundle.pathForResource(fileName, ofType: fileExtension)
            if path == nil { // If not found. Add png extension and try again
                path = bundle.pathForResource(fileName, ofType: "png")
            }
            return path
        }
        
        // Else, user is passing a common name. We will try to find the version match current scale first
        var path: String?
        let scale = Int(UIScreen.mainScreen().scale)
        
        path = bundle.pathForResource("\(fileName)@\(scale)x", ofType: fileExtension) ??
               bundle.pathForResource("\(fileName)@\(scale)x", ofType: "png") ??
               bundle.pathForResource(fileName, ofType: fileExtension) ?? // Matched scaled version not found, use the 1x version
               bundle.pathForResource(fileName, ofType: "png")
        
        return path
    }
}

