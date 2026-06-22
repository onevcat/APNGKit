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
    func testRenderDownsamplesToMaxSize() throws {
        // Baseline: rendering without a `maxRenderSize` keeps the native pixel size. This also guards the default path
        // against regression from the downsampling change.
        let nativeDecoder = try APNGDecoder(fileURL: SampleTesting.sampleTestingURL(name: "ball"))
        XCTAssertEqual(nativeDecoder.renderScale, 1.0)
        let nativeRenderer = try APNGImageRenderer(decoder: nativeDecoder)
        let nativeFrame0 = try nativeRenderer.output!.get()
        let width = nativeDecoder.imageHeader.width
        let height = nativeDecoder.imageHeader.height
        XCTAssertEqual(nativeFrame0.width, width)
        XCTAssertEqual(nativeFrame0.height, height)

        // Downsample to half. The output canvas — and every composited frame — must come out at the scaled size.
        let decoder = try APNGDecoder(
            fileURL: SampleTesting.sampleTestingURL(name: "ball"),
            maxRenderSize: CGSize(width: width / 2, height: height / 2)
        )
        XCTAssertEqual(decoder.renderScale, 0.5, accuracy: 0.0001)
        XCTAssertEqual(decoder.renderWidth, width / 2)
        XCTAssertEqual(decoder.renderHeight, height / 2)

        let renderer = try APNGImageRenderer(decoder: decoder)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.width, width / 2)
        XCTAssertEqual(frame0.height, height / 2)

        // The scaled size must hold across the compositing pipeline for subsequent frames, not just the first.
        let frame1 = try renderer.renderNextAndGetResult()
        XCTAssertEqual(frame1.width, width / 2)
        XCTAssertEqual(frame1.height, height / 2)
        let frame2 = try renderer.renderNextAndGetResult()
        XCTAssertEqual(frame2.width, width / 2)
        XCTAssertEqual(frame2.height, height / 2)
    }

    func testMaxSizeLargerThanNativeDoesNotUpscale() throws {
        // `maxRenderSize` is an upper bound only: an image already smaller than it is left at native size.
        let decoder = try APNGDecoder(
            fileURL: SampleTesting.sampleTestingURL(name: "ball"),
            maxRenderSize: CGSize(width: 10_000, height: 10_000)
        )
        XCTAssertEqual(decoder.renderScale, 1.0)
        let renderer = try APNGImageRenderer(decoder: decoder)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.width, decoder.imageHeader.width)
        XCTAssertEqual(frame0.height, decoder.imageHeader.height)
    }

    func testDownsamplingWithPreviousDisposal() throws {
        // `over_previous.apng` uses `.previous` dispose op. Rendering all frames with downsampling must not crash
        // or produce nil from `CGImage.cropping(to:)` — the exact scenario that fractional rects would break.
        let nativeDecoder = try APNGDecoder(
            fileURL: SampleTesting.sampleTestingURL(name: "over_previous"),
            options: [.fullFirstPass]
        )
        let width = nativeDecoder.imageHeader.width
        let height = nativeDecoder.imageHeader.height

        let decoder = try APNGDecoder(
            fileURL: SampleTesting.sampleTestingURL(name: "over_previous"),
            options: [.fullFirstPass],
            maxRenderSize: CGSize(width: width / 2, height: height / 2)
        )
        let renderer = try APNGImageRenderer(decoder: decoder)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.width, decoder.renderWidth)
        XCTAssertEqual(frame0.height, decoder.renderHeight)

        for _ in 1..<decoder.framesCount {
            let frame = try renderer.renderNextAndGetResult()
            XCTAssertEqual(frame.width, decoder.renderWidth)
            XCTAssertEqual(frame.height, decoder.renderHeight)
        }
    }

    func testDownsamplingWithPartialFrames() throws {
        // `spinfox.apng` uses partial-frame updates (sub-region fcTL with offsets). Downsampling must correctly
        // scale the sub-region rects so that composited output dimensions match the render canvas.
        let nativeDecoder = try APNGDecoder(
            fileURL: SampleTesting.sampleTestingURL(name: "spinfox"),
            options: [.fullFirstPass]
        )
        let width = nativeDecoder.imageHeader.width
        let height = nativeDecoder.imageHeader.height

        // Use a non-power-of-two scale to exercise fractional rect rounding.
        let decoder = try APNGDecoder(
            fileURL: SampleTesting.sampleTestingURL(name: "spinfox"),
            options: [.fullFirstPass],
            maxRenderSize: CGSize(width: width * 2 / 3, height: height * 2 / 3)
        )
        XCTAssertLessThan(decoder.renderScale, 1.0)

        let renderer = try APNGImageRenderer(decoder: decoder)
        let frame0 = try renderer.output!.get()
        XCTAssertEqual(frame0.width, decoder.renderWidth)
        XCTAssertEqual(frame0.height, decoder.renderHeight)

        for _ in 1..<decoder.framesCount {
            let frame = try renderer.renderNextAndGetResult()
            XCTAssertEqual(frame.width, decoder.renderWidth)
            XCTAssertEqual(frame.height, decoder.renderHeight)
        }
    }
}

extension APNGImageRenderer {
    func renderNextAndGetResult() throws -> CGImage {
        try renderNextSync()
        return try output!.get()
    }
}
