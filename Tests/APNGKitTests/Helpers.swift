//
//  Helpers.swift
//  
//
//  Created by Wang Wei on 2021/10/06.
//

import Foundation
@testable import APNGKit

struct SpecTesting {
    
    static func specTestingURL(_ index: Int) -> URL {
        Bundle.module.url(forResource: String(format: "%03d", index), withExtension: "png", subdirectory: "SpecTesting")!
    }
    
    static func reader(of index: Int) throws -> FileReader {
        try FileReader.init(url: specTestingURL(index))
    }
}



