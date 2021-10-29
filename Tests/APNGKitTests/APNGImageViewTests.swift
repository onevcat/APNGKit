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
        vc.view.layoutIfNeeded()
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
        
        let firstFrame = imageView.image!.decoder.frames.first!
        XCTAssertNotNil(firstFrame)
        
        // The Ball animation has identical frame duration for each frame.
        let frameDuration = firstFrame!.frameControl.duration
        timeWrap {
            XCTAssertEqual(imageView.image!.decoder.currentIndex, 0)
        }
        // Only ensure before the next frame. Display link requires synced with refresh rate...
        .after(frameDuration * 0.75) { }
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
}

class DeinitInspectableAPNGImageView: APNGImageView {
    let onDeinit = Delegate<(), Void>()
    
    deinit {
        onDeinit()
    }
}
