//
//  Helpers.swift
//  
//
//  Created by Wang Wei on 2021/10/06.
//

import Foundation
@testable import APNGKit
import XCTest

struct SpecTesting {
    
    static func specTestingURL(_ index: Int) -> URL {
        Bundle.module.url(forResource: String(format: "%03d", index), withExtension: "png", subdirectory: "SpecTesting")!
    }
    
    static func reader(of index: Int) throws -> FileReader {
        try FileReader.init(url: specTestingURL(index))
    }
}

func sampleImage(name: String) throws -> APNGImage {
    try APNGImage(named: name, in: .module, subdirectory: "General")
}

// Ball APNG: 100x100, 20 frames, duration 1.5s
func createBallImage() -> APNGImage {
    try! sampleImage(name: "ball")
}

func createMinimalImage() -> APNGImage {
    try! sampleImage(name: "minimal")
}

class TimeWrap {
    
    private var accumulated: TimeInterval = 0
    private let testCase: XCTestCase
    private let expectation: XCTestExpectation
    
    init(testCase: XCTestCase) {
        self.testCase = testCase
        self.expectation = testCase.expectation(description: "Time Wrap")
    }
    
    func after(_ delay: TimeInterval, block: @escaping () -> Void) -> TimeWrap {
        accumulated = accumulated + delay
        DispatchQueue.main.asyncAfter(deadline: .now() + accumulated, execute: block)
        return self
    }
    
    func done(){
        _ = after(0.0) { self.expectation.fulfill() }
        wait()
    }
    
    func wait() {
        testCase.waitForExpectations(timeout: accumulated + 0.1, handler: nil)
    }
}

extension XCTestCase {
    func timeWrap(perform block: () -> Void) -> TimeWrap {
        block()
        return TimeWrap(testCase: self)
    }

}
