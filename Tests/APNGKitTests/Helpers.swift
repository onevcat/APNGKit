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
    
    struct Item {
        let timeInterval: TimeInterval
        let block: () -> Void
    }
    
    private var accumulated: TimeInterval = 0
    private let testCase: XCTestCase
    private let expectation: XCTestExpectation
    
    private var items: [Item] = []
    private var passed = 0.0
    
    init(testCase: XCTestCase) {
        self.testCase = testCase
        self.expectation = testCase.expectation(description: "Time Wrap")
    }
    
    func after(_ delay: TimeInterval, block: @escaping () -> Void) -> TimeWrap {
        accumulated = accumulated + delay
        items.append(.init(timeInterval: accumulated, block: block))
        return self
    }
    
    func done(){
        Timer.scheduledTimer(timeInterval: 0.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        wait()
    }
    
    @objc func step(t: Timer) {
        passed = t.timeInterval + passed
        if let first = self.items.first {
            if passed >= first.timeInterval {
                first.block()
                self.items.removeFirst()
            }
        } else {
            t.invalidate()
            self.expectation.fulfill()
        }
    }
    
    func wait() {
        testCase.waitForExpectations(timeout: accumulated + 1, handler: nil)
    }
}

extension XCTestCase {
    func timeWrap(perform block: () -> Void) -> TimeWrap {
        block()
        return TimeWrap(testCase: self)
    }

}
