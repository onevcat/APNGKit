//
//  APNGKitError.swift
//  
//
//  Created by Wang Wei on 2021/10/05.
//

import Foundation
import ImageIO

/// The errors can be thrown or returned by APIs in APNGKit.
///
/// Each member in this type represents a type of reason for error during different image decoding or displaying phase.
/// Check the detail reason to know the details. In most cases, you are only care about one or two types of error, and
/// leave others falling to a default handling.
public enum APNGKitError: Error {
    /// Errors happening during decoding the image data.
    case decoderError(DecoderError)
    /// Errors happening during creating the image.
    case imageError(ImageError)
    /// Other errors happening inside system and not directly related to APNGKit.
    case internalError(Error)
}

extension APNGKitError {
    
    /// Errors happening during decoding the image data.
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
        case invalidRenderer
    }
    
    /// Errors happening during creating the image.
    public enum ImageError {
        case resourceNotFound(name: String, bundle: Bundle)
        case normalImageDataLoaded(data: Data, scale: CGFloat)
    }
}

extension APNGKitError {
    
    /// Returns the image data as a normal image if the error happens during creating image object.
    ///
    /// When the image cannot be loaded as an APNG, but can be represented as a normal image, this returns its data and
    /// a scale for the image.
    public var normalImageData: (Data, CGFloat)? {
        guard case .imageError(.normalImageDataLoaded(let data, let scale)) = self else {
            return nil
        }
        return (data, scale)
    }
}

extension Error {
    /// Converts `self` to an `APNGKitError` if it is.
    ///
    /// This is identical as `self as? APNGKitError`.
    public var apngError: APNGKitError? { self as? APNGKitError }
}

extension APNGKitError {
    var shouldRevertToNormalImage: Bool {
        switch self {
        case .decoderError(let reason):
            switch reason {
            case .chunkNameNotMatched(let expected, let actual):
                let isCgBI = expected == IHDR.name && actual == ["C", "g", "B", "I"]
                if isCgBI {
                    printLog("`CgBI` chunk found. It seems that the input image is compressed by Xcode and not supported by APNGKit. Consider to rename it to `apng` to prevent compressing.")
                }
                return isCgBI
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
