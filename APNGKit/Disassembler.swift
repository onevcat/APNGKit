//
//  Disassembler.swift
//  APNGKit
//
//  Created by WANG WEI on 2015/08/27.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import Foundation

let signatureOfPNGLength = 8

// Reading callback for libpng
func readData(pngPointer: png_structp, outBytes: png_bytep, byteCountToRead: png_size_t) {
    let ioPointer = png_get_io_ptr(pngPointer)
    var reader = UnsafePointer<Reader>(ioPointer).memory
    
    reader.read(outBytes, bytesCount: byteCountToRead)
}

enum DisassemblerError: ErrorType {
    case InvalidFormat
    case PNGStructureFailure
}

struct Disassembler {
    private(set) var reader: Reader
    let originalData: NSData
    
    init(data: NSData) {
        reader = Reader(data: data)
        originalData = data
    }
    
    mutating func decode() throws -> APNGImage {
        
        try checkFormat()

        let pngPointer = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        let infoPointer = png_create_info_struct(pngPointer)

        if pngPointer == nil || infoPointer == nil {
            throw DisassemblerError.PNGStructureFailure
        }
        
        png_set_read_fn(pngPointer, &reader, readData)
        
        return APNGImage()
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