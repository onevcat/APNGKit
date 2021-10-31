//
//  APNGImageViewTests.swift
//  
//
//  Created by Wang Wei on 2021/10/29.
//

import Foundation
import XCTest
import Delegate
@testable import APNGKit

#if canImport(UIKit)
class ViewControllerStub {
    
    var window: UIWindow!
    
    func setupViewController() -> UIViewController {
        let rootViewController =  UIViewController()
        return setupViewController(rootViewController)
    }
    
    func setupViewController(_ input: UIViewController) -> UIViewController {

        input.loadViewIfNeeded()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = input
        window.makeKeyAndVisible()
        return input
    }
    
    func resetViewController() {
        window.rootViewController = nil
        window = nil
    }
}
#endif

#if canImport(AppKit)

class ViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: .init(x: 0, y: 0, width: 100, height: 100))
    }
}

class ViewControllerStub {
    
    var window: NSWindow!
    
    func setupViewController() -> NSViewController {
        let rootViewController =  ViewController()
        return setupViewController(rootViewController)
    }
    
    func setupViewController(_ input: ViewController) -> NSViewController {

        _ = input.view
        window = NSWindow(contentRect: .init(x: 0, y: 0, width: 100, height: 100), styleMask: .borderless, backing: .buffered, defer: false)
        window.contentViewController = input
        return input
    }
    
    func resetViewController() {
        window = nil
    }
}
#endif

class APNGImageViewTests: XCTestCase {
    
    var viewControllerStub = ViewControllerStub()
    weak var imageView: APNGImageView?
    
    override func tearDown() {
        imageView = nil
    }
    
    func testInit() throws {
        let imageView = APNGImageView(frame: .zero)
        XCTAssertNil(imageView.image)
        XCTAssertFalse(imageView.isAnimating)
    }
    
    func testInitWithImage() throws {
        let apng = createBallImage()
        let imageView = APNGImageView(image: apng)
        XCTAssertEqual(imageView.intrinsicContentSize, apng.size)
        XCTAssertTrue(imageView.isAnimating)
    }
    
    func testLayoutByContentSize() throws {
        
        let apng = createBallImage()
        let imageView = APNGImageView(image: apng)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let vc = viewControllerStub.setupViewController()
        vc.view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])
        
        XCTAssertEqual(imageView.bounds, .zero)
        #if canImport(UIKit)
        vc.view.layoutIfNeeded()
        #elseif canImport(AppKit)
        vc.view.layoutSubtreeIfNeeded()
        #endif
        XCTAssertEqual(imageView.bounds, .init(origin: .zero, size: apng.size))
    }
    
    func testReleaseWhenNotAnimating() throws {
        var imageView: DeinitInspectableAPNGImageView?
        imageView = DeinitInspectableAPNGImageView(frame: .zero)
        
        var deinitCalled = false
        imageView?.onDeinit.delegate(on: self) { (self, _) in
            deinitCalled = true
        }
        imageView = nil
        XCTAssertTrue(deinitCalled)
    }
    
    func testReleaseWhenInitImage() throws {
        let apng = createBallImage()
        var imageView: DeinitInspectableAPNGImageView?
        imageView = DeinitInspectableAPNGImageView(image: apng)
        
        var deinitCalled = false
        imageView?.onDeinit.delegate(on: self) { (self, _) in
            deinitCalled = true
        }
        imageView = nil
        XCTAssertTrue(deinitCalled)
    }
    
    func testReleaseWhenInitImageWithoutAnimation() throws {
        let apng = createBallImage()
        var imageView: DeinitInspectableAPNGImageView?
        imageView = DeinitInspectableAPNGImageView(image: apng, autoStartAnimating: false)
        
        var deinitCalled = false
        imageView?.onDeinit.delegate(on: self) { (self, _) in
            deinitCalled = true
        }
        imageView = nil
        XCTAssertTrue(deinitCalled)
    }
    
    func testReleaseWhenSetImageWithoutAnimation() throws {
        var imageView: DeinitInspectableAPNGImageView?
        imageView = DeinitInspectableAPNGImageView(frame: .zero)
        imageView?.autoStartAnimationWhenSetImage = false
        
        let apng = createBallImage()
        imageView?.image = apng
        
        var deinitCalled = false
        imageView?.onDeinit.delegate(on: self) { (self, _) in
            deinitCalled = true
        }
        imageView = nil
        XCTAssertTrue(deinitCalled)
    }
    
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
        
        let firstFrame = imageView.image!.decoder.frames.first!
        XCTAssertNotNil(firstFrame)
        
        // The minimal animation has identical frame duration for each frame.
        let frameDuration = firstFrame!.frameControl.duration
        timeWrap {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.image!.decoder.currentIndex, 0)
        }
        // Only ensure before the next frame. Display link requires synced with refresh rate...
        .after(frameDuration * 0.6) {
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 1)
        }
        .after(frameDuration) {
            // Displaying this index.
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            // The next frame is prepared.
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 2)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 2)
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 3)
        }
        .after(frameDuration) {
            XCTAssertEqual(loopCount, 0)
            XCTAssertEqual(imageView.displayingFrameIndex, 3)
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 0)
        }
        .after(frameDuration) {
            XCTAssertEqual(loopCount, 1)
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 1)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 2)
        }
        .done()
    }
    
    func testAnimatingStart() throws {
        let apng = createMinimalImage()
        let imageView = APNGImageView(frame: .zero)
        imageView.autoStartAnimationWhenSetImage = false
        imageView.image = apng

        XCTAssertFalse(imageView.isAnimating)

        let firstFrame = imageView.image!.decoder.frames.first!
        let frameDuration = firstFrame!.frameControl.duration
        
        timeWrap {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
        }
        .after(frameDuration * 0.7) {
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 1)
        }
        .after(frameDuration) { // Animation is not started
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 1)
            XCTAssertFalse(imageView.isAnimating)
            
            imageView.startAnimating()
            XCTAssertTrue(imageView.isAnimating)
        }
        .after(frameDuration * 0.7) { }
        .after(frameDuration) { // Animation is going on...
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 2)
            XCTAssertTrue(imageView.isAnimating)
        }
        .done()
    }
    
    func testAnimatingStop() throws {
        let imageView = APNGImageView(image: createMinimalImage())
        XCTAssertTrue(imageView.isAnimating)
        let firstFrame = imageView.image!.decoder.frames.first!
        let frameDuration = firstFrame!.frameControl.duration
        timeWrap {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.image!.decoder.currentIndex, 0)
        }
        .after(frameDuration * 0.7) {
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 1)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 2)
            
            imageView.stopAnimating()
            XCTAssertFalse(imageView.isAnimating)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 2)
        }
        .done()
    }
    
    func testAllDone() throws {
        let apng = createMinimalImage()
        apng.numberOfPlays = 1
        let imageView = APNGImageView(image: apng)
        
        let firstFrame = imageView.image!.decoder.frames.first!
        let frameDuration = firstFrame!.frameControl.duration
        
        var allDone = false
        imageView.onAllPlaysDone.delegate(on: self) { (self, _) in
            allDone = true
        }
        timeWrap {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(imageView.image!.decoder.currentIndex, 0)
        }
        .after(frameDuration * 0.7) {
            XCTAssertEqual(imageView.image?.decoder.currentIndex, 1)
        }
        .after(frameDuration * 3) {
            XCTAssertEqual(imageView.displayingFrameIndex, 3)
            XCTAssertEqual(imageView.image!.decoder.currentIndex, 0)
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
    
    func testSettingImageWithOwner() throws {
        let apng = createBallImage()
        
        let imageView1 = APNGImageView(image: apng)
        let imageView2 = APNGImageView(image: apng)
        let imageView3 = APNGImageView(image: createBallImage())
        
        XCTAssertNotNil(imageView1.image)
        XCTAssertNil(imageView2.image)
        XCTAssertNotNil(imageView3.image)
    }
    
    func testSwitchingImage() throws {
        let ballAPNG = createBallImage()
        let minimalAPNG = createMinimalImage()
        
        let imageView = APNGImageView(image: ballAPNG)
        XCTAssertTrue(imageView.isAnimating)
        XCTAssertTrue(ballAPNG.owner === imageView)
        XCTAssertNil(minimalAPNG.owner)

        imageView.image = minimalAPNG
        XCTAssertTrue(imageView.isAnimating)
        XCTAssertNil(ballAPNG.owner)
        XCTAssertTrue(minimalAPNG.owner === imageView)
        
        imageView.image = nil
        XCTAssertFalse(imageView.isAnimating)
        XCTAssertNil(ballAPNG.owner)
        XCTAssertNil(minimalAPNG.owner)
    }
    
    func testSwitchingImageReset() throws {
        let minimalAPNG = createMinimalImage()
        let imageView = APNGImageView(image: minimalAPNG)
        
        let firstFrame = imageView.image!.decoder.frames.first!
        let frameDuration = firstFrame!.frameControl.duration
        
        timeWrap {}
        .after(frameDuration * 0.7) {}
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 1)
            XCTAssertEqual(minimalAPNG.decoder.currentIndex, 2)
            imageView.image = nil
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(minimalAPNG.decoder.currentIndex, 2)
        }
        .after(frameDuration) {
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(minimalAPNG.decoder.currentIndex, 2)
            imageView.image = minimalAPNG
            // original image should be reset
            XCTAssertEqual(imageView.displayingFrameIndex, 0)
            XCTAssertEqual(minimalAPNG.decoder.currentIndex, 0)
        }
        .done()
    }
}

class DeinitInspectableAPNGImageView: APNGImageView {
    let onDeinit = Delegate<(), Void>()
    
    deinit {
        onDeinit()
    }
}
