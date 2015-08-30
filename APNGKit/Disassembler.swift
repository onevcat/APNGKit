//
//  Disassembler.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

let signatureOfPNGLength = 8
let kMaxPNGSize = 1000000;

// Reading callback for libpng
func readData(pngPointer: png_structp, outBytes: png_bytep, byteCountToRead: png_size_t) {
    let ioPointer = png_get_io_ptr(pngPointer)
    var reader = UnsafePointer<Reader>(ioPointer).memory
    
    reader.read(outBytes, bytesCount: byteCountToRead)
}

enum DisassemblerError: ErrorType {
    case InvalidFormat
    case PNGStructureFailure
    case PNGInternalError
}

// APNG Specification: https://wiki.mozilla.org/APNG_Specification
public struct Disassembler {
    private(set) var reader: Reader
    let originalData: NSData
    
    init(data: NSData) {
        reader = Reader(data: data)
        originalData = data
    }
    
    mutating func decodeToElements() throws -> (frames: [Frame], size: CGSize, repeatCount: Int) {
        reader.beginReading()
        defer {
            reader.endReading()
        }
        
        try checkFormat()
        
        var pngPointer = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        if pngPointer == nil {
            throw DisassemblerError.PNGStructureFailure
        }
        
        var infoPointer = png_create_info_struct(pngPointer)
        if infoPointer == nil {
            png_destroy_read_struct(&pngPointer, &infoPointer, nil)
            throw DisassemblerError.PNGStructureFailure
        }
        
        if setjmp(png_jmpbuf(pngPointer)) != 0 {
            png_destroy_read_struct(&pngPointer, &infoPointer, nil)
            throw DisassemblerError.PNGInternalError
        }
        
        png_set_read_fn(pngPointer, &reader, readData)
        png_read_info(pngPointer, infoPointer)
        
        var
        width: UInt32 = 0,
        height: UInt32 = 0,
        bitDepth: Int32 = 0,
        colorType: Int32 = 0
        
        // Decode IHDR
        png_get_IHDR(pngPointer, infoPointer, &width, &height, &bitDepth, &colorType, nil, nil, nil)
        
        // Transforms. We only handle 8-bit RGBA images.
        png_set_expand(pngPointer)
        
        if bitDepth == 16 {
            png_set_strip_16(pngPointer)
        }
        
        if colorType == PNG_COLOR_TYPE_GRAY || colorType == PNG_COLOR_TYPE_GRAY_ALPHA {
            png_set_gray_to_rgb(pngPointer);
        }
        
        if colorType == PNG_COLOR_TYPE_RGB || colorType == PNG_COLOR_TYPE_GRAY {
            png_set_add_alpha(pngPointer, 0xff, PNG_FILLER_AFTER);
        }
        
        png_set_interlace_handling(pngPointer);
        png_read_update_info(pngPointer, infoPointer);
        
        // Update information from updated info pointer
        width = png_get_image_width(pngPointer, infoPointer)
        height = png_get_image_height(pngPointer, infoPointer)
        let rowBytes = UInt32(png_get_rowbytes(pngPointer, infoPointer))
        let length = height * rowBytes
        
        var bufferFrame = Frame(length: length, bytesInRow: rowBytes)
        var currentFrame = Frame(length: length, bytesInRow: rowBytes)
        var nextFrame: Frame!
        
        // Decode acTL
        var frameCount: UInt32 = 0, playCount: UInt32 = 0
        png_get_acTL(pngPointer, infoPointer, &frameCount, &playCount)
        
        if frameCount == 0 {
            // TODO: - Fallback to normal PNG
        }
        
        // Setup values for reading frames
        var
        frameWidth: UInt32 = 0,
        frameHeight: UInt32 = 0,
        offsetX: UInt32 = 0,
        offsetY: UInt32 = 0,
        delayNum: UInt16 = 0,
        delayDen: UInt16 = 0,
        disposeOP: UInt8 = 0,
        blendOP: UInt8 = 0
        
        let firstImageIndex: Int
        let firstFrameHidden = png_get_first_frame_is_hidden(pngPointer, infoPointer) != 0
        firstImageIndex = firstFrameHidden ? 1 : 0
        
        var frames = [Frame]()
        
        // Decode frames
        for i in 0 ..< frameCount {
            let currentIndex = Int(i)
            // Read header
            png_read_frame_head(pngPointer, infoPointer)
            // Decode fcTL
            png_get_next_frame_fcTL(pngPointer, infoPointer, &frameWidth, &frameHeight,
                &offsetX, &offsetY, &delayNum, &delayDen, &disposeOP, &blendOP)
            
            // Update disposeOP for first visable frame
            if currentIndex == firstImageIndex {
                blendOP = UInt8(PNG_BLEND_OP_SOURCE)
                if disposeOP == UInt8(PNG_DISPOSE_OP_PREVIOUS) {
                    disposeOP = UInt8(PNG_DISPOSE_OP_BACKGROUND)
                }
            }
            
            nextFrame = Frame(length: length, bytesInRow: rowBytes)
            
            if (disposeOP == UInt8(PNG_DISPOSE_OP_PREVIOUS)) {
                // For the first frame, currentFrame is not inited yet.
                // But we can ensure the disposeOP is not PNG_DISPOSE_OP_PREVIOUS for the 1st frame
                memcpy(nextFrame.bytes, currentFrame.bytes, Int(length));
            }
            
            // Decode fdATs
            png_read_image(pngPointer, &bufferFrame.byteRows)
            blendFrameDstBytes(currentFrame.byteRows, srcBytes: bufferFrame.byteRows, blendOP: blendOP, offsetX: offsetX, offsetY: offsetY, width: frameWidth, height: frameHeight)
            // Calculating delay (duration)
            if delayDen == 0 {
                delayDen = 100
            }
            let duration = Double(delayNum) / Double(delayDen)
            currentFrame.duration = duration
            currentFrame.hidden = true

            currentFrame.updateCGImageRef(Int(width), height: Int(height), bits: Int(bitDepth))
            
            frames.append(currentFrame)
            
            if disposeOP != UInt8(PNG_DISPOSE_OP_PREVIOUS) {
                memcpy(nextFrame.bytes, currentFrame.bytes, Int(length))
                if disposeOP == UInt8(PNG_DISPOSE_OP_BACKGROUND) {
                    for j in 0 ..< frameHeight {
                        let tarPointer = nextFrame.byteRows[Int(offsetY + j)].advancedBy(Int(offsetX) * 4)
                        memset(tarPointer, 0, Int(frameWidth) * 4)
                    }
                }
            }
            
            currentFrame.bytes = nextFrame.bytes
            currentFrame.byteRows = nextFrame.byteRows
        }
        
        // End
        png_read_end(pngPointer, infoPointer)
        
        bufferFrame.clean()
        currentFrame.clean()
        
        png_destroy_read_struct(&pngPointer, &infoPointer, nil)
        
        return (frames, CGSize(width: CGFloat(width), height: CGFloat(height)), Int(playCount) - 1)
    }
    
    public mutating func decode() throws -> APNGImage {
        let (frames, size, repeatCount) = try decodeToElements()

        // Setup apng properties
        let apng = APNGImage(frames: frames, size: size)
        apng.repeatCount = repeatCount
        
        return apng
    }
    
    func blendFrameDstBytes(dstBytes: Array<UnsafeMutablePointer<UInt8>>, srcBytes: Array<UnsafeMutablePointer<UInt8>>, blendOP: UInt8, offsetX: UInt32, offsetY: UInt32, width: UInt32, height: UInt32) {
        
        var u: Int = 0, v: Int = 0, al: Int = 0
        
        for j in 0 ..< Int(height) {
            var sp = srcBytes[j]
            var dp = (dstBytes[j + Int(offsetY)]).advancedBy(Int(offsetX) * 4) //We will always handle 4 channels and 8-bits
            
            if blendOP == UInt8(PNG_BLEND_OP_SOURCE) {
                memcpy(dp, sp, Int(width) * 4)
            } else { // APNG_BLEND_OP_OVER
                for var i = 0; i < Int(width); i++, sp = sp.advancedBy(4), dp = dp.advancedBy(4) {
                    let srcAlpha = Int(sp.advancedBy(3).memory) // Blend alpha to dst
                    if srcAlpha == 0xff {
                        memcpy(dp, sp, 4)
                    } else if srcAlpha != 0 {
                        let dstAlpha = Int(dp.advancedBy(3).memory)
                        if dstAlpha != 0 {
                            u = srcAlpha * 255
                            v = (255 - srcAlpha) * dstAlpha
                            al = u + v
                            
                            for bit in 0 ..< 3 {
                                dp.advancedBy(bit).memory = UInt8(
                                    (Int(sp.advancedBy(bit).memory) * u + Int(dp.advancedBy(bit).memory) * v) / al
                                )
                            }
                            
                            dp.advancedBy(4).memory = UInt8(al / 255)
                        } else {
                            memcpy(dp, sp, 4)
                        }
                    }
                }
            }
        }
    }
    
    func checkFormat() throws {
        guard originalData.length > 8 else {
            throw DisassemblerError.InvalidFormat
        }
        
        var sig = [UInt8](count: signatureOfPNGLength, repeatedValue: 0)
        originalData.getBytes(&sig, length: signatureOfPNGLength)
        
        guard png_sig_cmp(&sig, 0, signatureOfPNGLength) == 0 else {
            throw DisassemblerError.InvalidFormat
        }
    }
}