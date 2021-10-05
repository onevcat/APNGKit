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
    }
}
