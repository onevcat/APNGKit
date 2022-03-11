//
//  APNGImageViewTimingTests.swift
//  
//
//  Created by Wang Wei on 2021/11/01.
//

import Foundation
import XCTest
import Delegate
@testable import APNGKit

// Timing related tests. CI is not suitable for these tests. They will be removed before testing on CI.
class APNGImageViewTimingTests: XCTestCase {
    func testAnimatingPlay() throws {
        let imageView = APNGImageView(image: createMinimalImage())
        XCTAssertTrue(imageView.isAnimating)
        
        var loopCount = 0
        imageView.onOnePlayDone.delegate(on: self) { (self, count) in
            loopCount = count
        }
        imageView.onFrameMissed.delegate(on: self) { (self, index) in
            XCTFail("Frame missed, index: \(index). CI node performance is not enough.")
        }
        
        let firstFrame = imageView.image!.decoder.loadedFrames.first!
        XCTAssertNotNil(firstFrame)
        
        // The minimal animation has identical frame duration for each frame.
        let frameDuration = firstFrame.frameControl.duration
        timeWrap {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.renderer?.currentIndex, 0)
        }
        // Only ensure before the next frame. Display link requires synced with refresh rate...
        .after(frameDuration * 0.5) {
            XCTAssertEqual(imageView.renderer?.currentIndex, 1)
        }
        .after(frameDuration) {
            // Displaying this index.
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            // The next frame is prepared.
            XCTAssertEqual(imageView.renderer?.currentIndex, 2)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 2)
            XCTAssertEqual(imageView.renderer?.currentIndex, 3)
        }
        .after(frameDuration) {
            XCTAssertEqual(loopCount, 0)
            XCTAssertEqual(imageView.displayingFrameIndex, 3)
            XCTAssertEqual(imageView.renderer?.currentIndex, 0)
        }
        .after(frameDuration) {
            XCTAssertEqual(loopCount, 1)
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.renderer?.currentIndex, 1)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.renderer?.currentIndex, 2)
        }
        .done()
    }

    func testAnimatingStart() throws {
        let apng = createMinimalImage()
        let imageView = APNGImageView(frame: .zero)
        imageView.autoStartAnimationWhenSetImage = false
        imageView.image = apng

        XCTAssertFalse(imageView.isAnimating)

        let firstFrame = imageView.image!.decoder.loadedFrames.first!
        let frameDuration = firstFrame.frameControl.duration
        
        timeWrap {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
        }
        .after(frameDuration * 0.5) {
            XCTAssertEqual(imageView.renderer?.currentIndex, 1)
        }
        .after(frameDuration) { // Animation is not started
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.renderer?.currentIndex, 1)
            XCTAssertFalse(imageView.isAnimating)
            
            imageView.startAnimating()
            XCTAssertTrue(imageView.isAnimating)
        }
        .after(frameDuration * 0.5) { }
        .after(frameDuration) { // Animation is going on...
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.renderer?.currentIndex, 2)
            XCTAssertTrue(imageView.isAnimating)
        }
        .done()
    }

    func testAnimatingStop() throws {
        let imageView = APNGImageView(image: createMinimalImage())
        XCTAssertTrue(imageView.isAnimating)
        let firstFrame = imageView.image!.decoder.loadedFrames.first!
        let frameDuration = firstFrame.frameControl.duration
        timeWrap {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.renderer?.currentIndex, 0)
        }
        .after(frameDuration * 0.5) {
            XCTAssertEqual(imageView.renderer?.currentIndex, 1)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.renderer?.currentIndex, 2)
            
            imageView.stopAnimating()
            XCTAssertFalse(imageView.isAnimating)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.renderer?.currentIndex, 2)
        }
        .done()
    }

    func testAllDone() throws {
        let apng = createMinimalImage()
        apng.numberOfPlays = 1
        let imageView = APNGImageView(image: apng)
        
        let firstFrame = imageView.image!.decoder.loadedFrames.first!
        let frameDuration = firstFrame.frameControl.duration
        
        var allDone = false
        imageView.onAllPlaysDone.delegate(on: self) { (self, _) in
            allDone = true
        }
        timeWrap {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.renderer?.currentIndex, 0)
        }
        .after(frameDuration * 0.5) {
            XCTAssertEqual(imageView.renderer?.currentIndex, 1)
        }
        .after(frameDuration * 3) {
            XCTAssertEqual(imageView.displayingFrameIndex, 3)
            XCTAssertEqual(imageView.renderer?.currentIndex, 0)
            XCTAssertTrue(imageView.isAnimating)
            XCTAssertFalse(allDone)
        }
        .after(frameDuration) {
            // Animation stops at the final frame.
            XCTAssertEqual(imageView.displayingFrameIndex, 3)
            XCTAssertFalse(imageView.isAnimating)
            XCTAssertTrue(allDone)
        }
        .done()
    }


    
    func testSwitchingImageReset() throws {
        let minimalAPNG = createMinimalImage()
        let imageView = APNGImageView(image: minimalAPNG)
        
        let firstFrame = imageView.image!.decoder.loadedFrames.first!
        let frameDuration = firstFrame.frameControl.duration
        
        timeWrap {}
        .after(frameDuration * 0.5) {}
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.renderer?.currentIndex, 2)
            imageView.image = nil
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertNil(imageView.renderer)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertNil(imageView.renderer)
            imageView.image = minimalAPNG
            // original image should be reset
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.renderer?.currentIndex, 0)
        }
        .done()
    }

}
