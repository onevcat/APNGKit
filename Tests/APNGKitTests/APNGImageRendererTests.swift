//
//  APNGImageRendererTests.swift
//  
//
//  Created by Wang Wei on 2022/03/11.
//

import XCTest
@testable import APNGKit

class APNGImageRendererTests: XCTestCase {
    
    func testRenderCorrectFrames() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        let renderer = try APNGImageRenderer(decoder: decoder)
        XCTAssertNotNil(renderer.output)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.height, 64)
        XCTAssertEqual(renderer.currentIndex, 0)
        
        let frame1 = try renderer.renderNextAndGetResult()
        XCTAssertEqual(frame1.height, 64)
        XCTAssertEqual(renderer.currentIndex, 1)
        
        let frame2 = try renderer.renderNextAndGetResult()
        XCTAssertEqual(frame2.height, 64)
        XCTAssertEqual(renderer.currentIndex, 2)
        
        let frame3 = try renderer.renderNextAndGetResult()
        XCTAssertEqual(frame3.height, 64)
        XCTAssertEqual(renderer.currentIndex, 3)
        
        let frame0_ = try renderer.renderNextAndGetResult()
        XCTAssertEqual(frame0_.height, 64)
        XCTAssertEqual(renderer.currentIndex, 0)
    }
    
    func testRenderAsync() throws {
        
        let expectation = expectation(description: "wait")
        
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        let renderer = try APNGImageRenderer(decoder: decoder)
        
        XCTAssertNotNil(renderer.output)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.height, 64)
        XCTAssertEqual(renderer.currentIndex, 0)
        
        renderer.renderNext()
        XCTAssertEqual(renderer.currentIndex, 0)
        
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 0.0001, repeats: true) { timer in
                if renderer.output == nil {
                    XCTAssertEqual(renderer.currentIndex, 0)
                } else {
                    let image = try? renderer.output?.get()
                    XCTAssertNotNil(image)
                    XCTAssertEqual(renderer.currentIndex, 1)
                    timer.invalidate()
                    expectation.fulfill()
                }
            }
        } else {
            // Fallback on earlier versions
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testRenderMultipleLoops() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        let renderer = try APNGImageRenderer(decoder: decoder)
        
        XCTAssertNotNil(renderer.output)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.height, 64)
        XCTAssertEqual(renderer.currentIndex, 0)
        
        do {
            for i in 1 ..< 100 {
                let _ = try renderer.renderNextAndGetResult()
                XCTAssertEqual(renderer.currentIndex, i % 4)
            }
        } catch {
            XCTFail()
        }
    }
    
    func testRendererCanResetToInitState() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        let renderer = try APNGImageRenderer(decoder: decoder)
        
        XCTAssertNotNil(renderer.output)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.height, 64)
        XCTAssertEqual(renderer.currentIndex, 0)
                
        for resetAt in 0 ... 10 {
            for i in 0 ..< resetAt {
                _ = try renderer.renderNextAndGetResult()
                XCTAssertEqual(renderer.currentIndex, (i + 1) % 4)
            }
            try renderer.reset()
            XCTAssertEqual(renderer.currentIndex, 0)

            _ = try renderer.renderNextAndGetResult()
            XCTAssertEqual(renderer.currentIndex, 1)
            
            _ = try renderer.renderNextAndGetResult()
            XCTAssertEqual(renderer.currentIndex, 2)
            
            _ = try renderer.renderNextAndGetResult()
            XCTAssertEqual(renderer.currentIndex, 3)
            
            _ = try renderer.renderNextAndGetResult()
            XCTAssertEqual(renderer.currentIndex, 0)
            
            _ = try renderer.renderNextAndGetResult()
            XCTAssertEqual(renderer.currentIndex, 1)
            
            try renderer.reset()
        }
    }
    
    func testRendererCanResetToInitStateBeforeFirstPass() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        let renderer = try APNGImageRenderer(decoder: decoder)
        XCTAssertNotNil(renderer.output)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.height, 64)
        XCTAssertEqual(renderer.currentIndex, 0)
                
        for resetAt in 0 ... 10 {
            for i in 0 ..< resetAt {
                _ = try renderer.renderNextAndGetResult()
                XCTAssertEqual(renderer.currentIndex, (i + 1) % 4)
            }
            try renderer.reset()
            XCTAssertEqual(renderer.currentIndex, 0)

            _ = try renderer.renderNextAndGetResult()
            XCTAssertEqual(renderer.currentIndex, 1)
            
            try renderer.reset()
        }
    }
    
    func testRendererCanResetToInitStateAtIndexZero() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        let renderer = try APNGImageRenderer(decoder: decoder)
        XCTAssertNotNil(renderer.output)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.height, 64)
        XCTAssertEqual(renderer.currentIndex, 0)
                
        for resetAt in 0 ... 10 {
            for i in 0 ..< resetAt {
                _ = try renderer.renderNextAndGetResult()
                XCTAssertEqual(renderer.currentIndex, (i + 1) % 4)
            }
            try renderer.reset()
            XCTAssertEqual(renderer.currentIndex, 0)
            try renderer.reset()
        }
    }
    
    func testMultipleRenderer() throws {
        let decoder = try APNGDecoder(fileURL: SpecTesting.specTestingURL(25))
        
        let renderer1 = try APNGImageRenderer(decoder: decoder)
        let renderer2 = try APNGImageRenderer(decoder: decoder)
        
        XCTAssertNotNil(renderer1.output)
        let frame1_0 = try renderer1.output!.get()
        XCTAssertEqual(frame1_0.height, 64)
        XCTAssertEqual(renderer1.currentIndex, 0)
        
        XCTAssertNotNil(renderer2.output)
        let frame2_0 = try renderer2.output!.get()
        XCTAssertEqual(frame2_0.height, 64)
        XCTAssertEqual(renderer2.currentIndex, 0)
        
        _ = try renderer1.renderNextAndGetResult()
        XCTAssertEqual(renderer1.currentIndex, 1)
        XCTAssertEqual(renderer2.currentIndex, 0)
        
        _ = try renderer1.renderNextAndGetResult()
        XCTAssertEqual(renderer1.currentIndex, 2)
        XCTAssertEqual(renderer2.currentIndex, 0)
        
        _ = try renderer2.renderNextAndGetResult()
        XCTAssertEqual(renderer1.currentIndex, 2)
        XCTAssertEqual(renderer2.currentIndex, 1)
        
        try renderer1.reset()
        XCTAssertEqual(renderer1.currentIndex, 0)
        XCTAssertEqual(renderer2.currentIndex, 1)
        
        _ = try renderer1.renderNextAndGetResult()
        XCTAssertEqual(renderer1.currentIndex, 1)
        XCTAssertEqual(renderer2.currentIndex, 1)
        
        _ = try renderer2.renderNextAndGetResult()
        XCTAssertEqual(renderer1.currentIndex, 1)
        XCTAssertEqual(renderer2.currentIndex, 2)
    }
}

extension APNGImageRenderer {
    func renderNextAndGetResult() throws -> CGImage {
        try renderNextSync()
        return try output!.get()
    }
}
