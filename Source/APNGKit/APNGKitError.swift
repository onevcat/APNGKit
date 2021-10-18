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
        case chunkNameNotMatched(expected: [Character], actual: [Character])
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
        case multipleAnimationControlChunk
    }
    
    public enum ImageError {
        case resourceNotFound(name: String, bundle: Bundle)
        case normalImageDataLoaded(image: UIImage)
    }
    
}

extension Error {
    public var apngError: APNGKitError? { self as? APNGKitError }
}

extension APNGKitError {
    var shouldRevertToNormalImage: Bool {
        switch self {
        case .decoderError(let reason):
            switch reason {
            case .chunkNameNotMatched(let expected, let actual):
                return expected == IHDR.name && actual == ["C", "g", "B", "I"]
            case .lackOfChunk(let name):
                return name == acTL.name
            default:
                return false
            }
        case .imageError:
            return false
        case .internalError:
            return false
        }
    }
}
