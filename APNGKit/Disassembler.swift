//
//  Disassembler.swift
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

#if os(macOS)
    import Cocoa
#else
    import UIKit
#endif

let signatureOfPNGLength = 8
let kMaxPNGSize: UInt32 = 1000000;

// Reading callback for libpng
func readData(_ pngPointer: png_structp?, outBytes: png_bytep?, byteCountToRead: png_size_t) {
    if pngPointer == nil || outBytes == nil {
        return
    }
    
    let ioPointer = png_get_io_ptr(pngPointer)
    var reader = UnsafeRawPointer(ioPointer)!.load(as: Reader.self)
    
    _ = reader.read(outBytes!, bytesCount: byteCountToRead)
}

struct APNGMeta {
    let width: UInt32
    let height: UInt32
    let bitDepth: UInt32
    let colorType: UInt32
    let rowBytes: UInt32
    let frameCount: UInt32
    let playCount: UInt32
    
    let firstFrameHidden: Bool
    
    var length: UInt32 {
        return height * rowBytes
    }
    
    var firstImageIndex: Int {
        return firstFrameHidden ? 1 : 0
    }
}

/**
Disassembler Errors. An error will be thrown if the disassembler encounters
unexpected error.

- InvalidFormat:       The file is not a PNG format.
- PNGStructureFailure: Fail on creating a PNG structure. It might due to out of memory.
- PNGInternalError:    Internal error when decoding a PNG image.
- FileSizeExceeded:    The file is too large. There is a limitation of APNGKit that the max width and height is 1M pixel.
*/
public enum DisassemblerError: Error {
    case invalidFormat
    case pngStructureFailure
    case pngInternalError
    case fileSizeExceeded
    case invalidAPNGMeta
}

/**
*  Disassemble APNG data. 
*  See APNG Specification: https://wiki.mozilla.org/APNG_Specification for defination of APNG.
*  This Disassembler is using a patched libpng with supporting of apng to read APNG data.
*  See https://github.com/onevcat/libpng for more.
*/
class Disassembler {
    fileprivate(set) var reader: Reader
    let originalData: Data
    
    fileprivate var processing = false
    fileprivate var pngPointer: png_structp?
    fileprivate var infoPointer: png_infop?
    
    fileprivate(set) var apngMeta: APNGMeta?
    fileprivate let scale: CGFloat
    fileprivate var currentFrameIndex: Int = 0

    fileprivate var bufferFrame: Frame!
    fileprivate var currentFrame: Frame!
    
    
    /**
    Init a disassembler with APNG data.
    
    - parameter data: Data object of an APNG file.
    
    - returns: The disassembler ready to use.
    */
    public init(data: Data, scale: CGFloat = 1) {
        reader = Reader(data: data)
        originalData = data
        self.scale = scale
    }
    
    

    func readRegularPNGFrame() -> Frame? {
        guard let apngMeta = apngMeta else { return nil }
        guard currentFrameIndex == 0 else { return nil }
        
        defer { currentFrameIndex += 1 }
        
        // Fallback to regular PNG
        let currentFrame = Frame(length: apngMeta.length, bytesInRow: apngMeta.rowBytes)
        currentFrame.duration = Double.infinity
        
        currentFrame.byteRows.withUnsafeMutableBufferPointer({ (buffer) in
            _ = withUnsafeMutablePointer(to: &buffer) { (bound) in
                bound.withMemoryRebound(to: (UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>).self, capacity: MemoryLayout<(UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>)>.size) { (rows) in
                    let mappedRows: UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>> = rows
                    png_read_image(pngPointer, mappedRows.pointee)
                }
            }
        })
        
        currentFrame.updateCGImageRef(Int(apngMeta.width), height: Int(apngMeta.height), bits: Int(apngMeta.bitDepth), scale: scale, blend: false)
        png_read_end(pngPointer, infoPointer)
        
        return currentFrame
    }

    func readNextFrame() -> Frame? {
        
        guard let apngMeta = apngMeta else { return nil }
        guard currentFrameIndex < Int(apngMeta.frameCount) else {
            png_read_end(pngPointer, infoPointer)
            return nil
        }
        
        defer { currentFrameIndex += 1 }
        
        var
        frameWidth: UInt32 = 0,
        frameHeight: UInt32 = 0,
        offsetX: UInt32 = 0,
        offsetY: UInt32 = 0,
        delayNum: UInt16 = 0,
        delayDen: UInt16 = 0,
        disposeOP: UInt8 = 0,
        blendOP: UInt8 = 0
        
        // Read header
        png_read_frame_head(pngPointer, infoPointer)
        // Decode fcTL
        png_get_next_frame_fcTL(pngPointer, infoPointer, &frameWidth, &frameHeight,
                                &offsetX, &offsetY, &delayNum, &delayDen, &disposeOP, &blendOP)
        if currentFrameIndex == apngMeta.firstImageIndex {
            blendOP = UInt8(PNG_BLEND_OP_SOURCE)
            if disposeOP == UInt8(PNG_DISPOSE_OP_PREVIOUS) {
                disposeOP = UInt8(PNG_DISPOSE_OP_BACKGROUND)
            }
        }
        
        let nextFrame = Frame(length: apngMeta.length, bytesInRow: apngMeta.rowBytes)
        if (disposeOP == UInt8(PNG_DISPOSE_OP_PREVIOUS)) {
            // For the first frame, currentFrame is not inited yet.
            // But we can ensure the disposeOP is not PNG_DISPOSE_OP_PREVIOUS for the 1st frame
            memcpy(nextFrame.bytes, currentFrame.bytes, Int(apngMeta.length));
        }
        
        // Decode fdATs
        bufferFrame.byteRows.withUnsafeMutableBufferPointer({ (buffer) in
            _ = withUnsafeMutablePointer(to: &buffer) { (bound) in
                bound.withMemoryRebound(to: (UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>).self, capacity: MemoryLayout<(UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>)>.size) { (rows) in
                    let mappedRows: UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>> = rows
                    png_read_image(pngPointer, mappedRows.pointee)
                }
            }
        })
        
        _ = withUnsafeMutablePointer(to: &currentFrame.byteRows) { (currentBind) in
            currentBind.withMemoryRebound(to: Array<UnsafeMutablePointer<UInt8>>.self, capacity: currentFrame.byteRows.count) { (currentRows) in
                let destRows: UnsafeMutablePointer<Array<UnsafeMutablePointer<UInt8>>> = currentRows
                
                _ = withUnsafeMutablePointer(to: &bufferFrame.byteRows) { (bufferBind) in
                    bufferBind.withMemoryRebound(to: Array<UnsafeMutablePointer<UInt8>>.self, capacity: bufferFrame.byteRows.count) { (bufferRows) in
                        let srcRows: UnsafeMutablePointer<Array<UnsafeMutablePointer<UInt8>>> = bufferRows
                        
                        blendFrameDstBytes(destRows.pointee, srcBytes: srcRows.pointee, blendOP: blendOP, offsetX: offsetX, offsetY: offsetY, width: frameWidth, height: frameHeight)
                    }
                }
            }
        }
        
        // Calculating delay (duration)
        if delayDen == 0 {
            delayDen = 100
        }
        let duration = Double(delayNum) / Double(delayDen)
        currentFrame.duration = duration
        
        currentFrame.updateCGImageRef(Int(apngMeta.width), height: Int(apngMeta.height), bits: Int(apngMeta.bitDepth), scale: scale, blend: blendOP != UInt8(PNG_BLEND_OP_SOURCE))
        
        if disposeOP != UInt8(PNG_DISPOSE_OP_PREVIOUS) {
            memcpy(nextFrame.bytes, currentFrame.bytes, Int(apngMeta.length))
            if disposeOP == UInt8(PNG_DISPOSE_OP_BACKGROUND) {
                for j in 0 ..< frameHeight {
                    let tarPointer = nextFrame.byteRows[Int(offsetY + j)].advanced(by: Int(offsetX) * 4)
                    memset(tarPointer, 0, Int(frameWidth) * 4)
                }
            }
        }
        
        defer { currentFrame = nextFrame }
        return currentFrame
    }
    
    func prepare() throws {
        reader.beginReading()
        try checkFormat()
        
        pngPointer = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        if pngPointer == nil {
            throw DisassemblerError.pngStructureFailure
        }
        
        infoPointer = png_create_info_struct(pngPointer)
        if infoPointer == nil {
            throw DisassemblerError.pngStructureFailure
        }

        if png_jmpbuf(pngPointer).pointee != 0 {
            throw DisassemblerError.pngInternalError
        }
        
        png_set_read_fn(pngPointer, &reader, readData)
        png_read_info(pngPointer, infoPointer)
        
        var
        w: UInt32 = 0,
        h: UInt32 = 0,
        bitDepth: Int32 = 0,
        colorType: Int32 = 0
        
        // Decode IHDR
        png_get_IHDR(pngPointer, infoPointer, &w, &h, &bitDepth, &colorType, nil, nil, nil)
        
        if w > kMaxPNGSize || h > kMaxPNGSize {
            throw DisassemblerError.fileSizeExceeded
        }
        
        // Transforms. We only handle 8-bit RGBA images.
        png_set_expand(pngPointer)
        
        if bitDepth == 16 {
            png_set_strip_16(pngPointer)
        }
        
        if colorType == PNG_COLOR_TYPE_GRAY || colorType == PNG_COLOR_TYPE_GRAY_ALPHA {
            png_set_gray_to_rgb(pngPointer);
        }
        
        if colorType == PNG_COLOR_TYPE_RGB || colorType == PNG_COLOR_TYPE_PALETTE || colorType == PNG_COLOR_TYPE_GRAY {
            png_set_add_alpha(pngPointer, 0xff, PNG_FILLER_AFTER);
        }
        
        png_set_interlace_handling(pngPointer);
        png_read_update_info(pngPointer, infoPointer);

        // Update information from updated info pointer
        let width = png_get_image_width(pngPointer, infoPointer)
        let height = png_get_image_height(pngPointer, infoPointer)
        let rowBytes = UInt32(png_get_rowbytes(pngPointer, infoPointer))

        // Decode acTL
        var frameCount: UInt32 = 0, playCount: UInt32 = 0
        png_get_acTL(pngPointer, infoPointer, &frameCount, &playCount)
        
        let firstFrameHidden: Bool
        if frameCount == 0 {
            firstFrameHidden = false
        } else {
            firstFrameHidden = png_get_first_frame_is_hidden(self.pngPointer, self.infoPointer) != 0
        }

        // Setup apng meta
        let meta = APNGMeta(
            width: width,
            height: height,
            bitDepth: UInt32(bitDepth),
            colorType: UInt32(colorType),
            rowBytes: rowBytes,
            frameCount: frameCount,
            playCount: playCount,
            firstFrameHidden: firstFrameHidden)
        
        bufferFrame = Frame(length: meta.length, bytesInRow: meta.rowBytes)
        currentFrame = Frame(length: meta.length, bytesInRow: meta.rowBytes)
        apngMeta = meta
    }
    
    func clean() {
        
        // Do not clean apng meta here. We will need it to return some meta to outside.
        
        processing = false
        currentFrameIndex = 0
        
        png_destroy_read_struct(&pngPointer, &infoPointer, nil)
        
        reader.endReading()

        if bufferFrame != nil {
            bufferFrame.clean()
            bufferFrame = nil
        }
        if currentFrame != nil {
            currentFrame.clean()
            currentFrame = nil
        }
    }
    
    /**
    Decode the data to a high level `APNGImage` object.
    
    - parameter scale: The screen scale should be used when decoding. 
    You should pass 1 if you want to use the dosassembler separately.
    If you need to display the image on the screen later, use `UIScreen.mainScreen().scale`.
    Default is 1.0.
    
    - throws: A `DisassemblerError` when error happens.
    
    - returns: A decoded `APNGImage` object at given scale.
    */
    public func decode(_ scale: CGFloat = 1) throws -> APNGImage {
        let (frames, meta) = try decodeToElements(scale)
        
        // Setup apng properties
        let apng = APNGImage(frames: frames, scale: scale, meta: meta)
        return apng
    }
    
    func decodeToElements(_ scale: CGFloat = 1) throws
            -> (frames: [Frame], APNGMeta)
    {
        var frames = [Frame]()
        while let frame = next() {
            frames.append(frame)
        }
        guard let apngMeta = apngMeta else {
            throw DisassemblerError.invalidAPNGMeta
        }
        return (frames, apngMeta)
    }
    
    func decodeMeta() throws -> APNGMeta {
        try prepare()
        clean()
        
        guard let apngMeta = apngMeta else {
            throw DisassemblerError.invalidAPNGMeta
        }
        return apngMeta
    }
    
    func blendFrameDstBytes(_ dstBytes: Array<UnsafeMutablePointer<UInt8>>,
                            srcBytes: Array<UnsafeMutablePointer<UInt8>>,
                             blendOP: UInt8,
                             offsetX: UInt32,
                             offsetY: UInt32,
                               width: UInt32,
                              height: UInt32)
    {
        var u: Int = 0, v: Int = 0, al: Int = 0
        
        for j in 0 ..< Int(height) {
            var sp = srcBytes[j]
            var dp = (dstBytes[j + Int(offsetY)]).advanced(by: Int(offsetX) * 4) //We will always handle 4 channels and 8-bits
            
            if blendOP == UInt8(PNG_BLEND_OP_SOURCE) {
                memcpy(dp, sp, Int(width) * 4)
            } else { // APNG_BLEND_OP_OVER
                for _ in 0 ..< Int(width){
                    
                    let srcAlpha = Int(sp.advanced(by: 3).pointee) // Blend alpha to dst
                    if srcAlpha == 0xff {
                        memcpy(dp, sp, 4)
                    } else if srcAlpha != 0 {
                        let dstAlpha = Int(dp.advanced(by: 3).pointee)
                        if dstAlpha != 0 {
                            u = srcAlpha * 255
                            v = (255 - srcAlpha) * dstAlpha
                            al = u + v
                            
                            for bit in 0 ..< 3 {
                                dp.advanced(by: bit).pointee = UInt8(
                                    (Int(sp.advanced(by: bit).pointee) * u + Int(dp.advanced(by: bit).pointee) * v) / al
                                )
                            }
                            
                            dp.advanced(by: 4).pointee = UInt8(al / 255)
                        } else {
                            memcpy(dp, sp, 4)
                        }
                    }
                    
                    sp = sp.advanced(by: 4)
                    dp = dp.advanced(by: 4)
                }
            }
        }
    }
    
    func checkFormat() throws {
        guard originalData.count > 8 else {
            throw DisassemblerError.invalidFormat
        }
        
        var sig = [UInt8](repeating: 0, count: signatureOfPNGLength)
        (originalData as NSData).getBytes(&sig, length: signatureOfPNGLength)
        
        guard png_sig_cmp(&sig, 0, signatureOfPNGLength) == 0 else {
            throw DisassemblerError.invalidFormat
        }
    }
}

extension Disassembler: IteratorProtocol {
    func next() -> Frame? {
        if !processing {
            processing = true
            do {
                try prepare()
            } catch {
                clean()
                return nil
            }
        }
        
        let result: Frame?
        
        guard let apngMeta = apngMeta else { return nil }
        
        // Regular
        if apngMeta.frameCount == 0 {
            result = readRegularPNGFrame()
        } else {
            result = readNextFrame()
        }
        
        if result == nil { clean() }
        return result
    }
}
