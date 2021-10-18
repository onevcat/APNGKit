//
//  File.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation
import ImageIO
import UIKit

public enum APNGKitError: Error {
    case decoderError(DecoderError)
    case imageError(ImageError)
    
    case internalError(Error)
}

extension APNGKitError {
    public enum DecoderError {
        case fileHandleCreatingFailed(URL, Error)
        case fileHandleOperationFailed(FileHandle, Error)
        case wrongChunkData(name: String, data: Data)
        case fileFormatError
        case corruptedData(atOffset: UInt64?)
        case invalidNumberOfFrames(value: Int)
        case invalidChecksum
        case lackOfChunk([Character])
        case wrongSequenceNumber(expected: Int, got: Int)
        case imageDataNotFound
        case frameDataNotFound(expectedSequence: Int)
        case invalidFrameImageData(data: Data, frameIndex: Int)
        case frameImageCreatingFailed(source: CGImageSource, frameIndex: Int)
        case outputImageCreatingFailed(frameIndex: Int)
        case canvasCreatingFailed
    }
    
    public enum ImageError {
        case resourceNotFound(name: String, bundle: Bundle)
        case normalImageDataLoaded(image: UIImage)
    }
    
}

extension Error {
    public var apngError: APNGKitError? { self as? APNGKitError }
}
