//
//  File.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation

public enum APNGKitError: Error {
    case decoderError(DecoderError)
}

extension APNGKitError {
    public enum DecoderError {
        case fileHandleCreatingFailed(URL, Error)
        case fileHandleOperationFailed(FileHandle, Error)
        case wrongChunkData(name: String, data: Data)
        case fileFormatError
        case corruptedData(atOffset: UInt64?)
        case invalidChecksum
        case lackOfChunk([Character])
        case wrongSequenceNumber(expected: Int, got: Int)
        case imageDataNotFound
        case frameDataNotFound(expectedSequence: Int)
    }
}

extension Error {
    var apngError: APNGKitError? { self as? APNGKitError }
}
