//
//  SampleImageFrameViewController.swift
//  Demo
//
//  Created by Wang Wei on 2021/12/06.
//

import UIKit
import APNGKit

class SampleImageFrameViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var image: APNGImage?
    var frames: [APNGFrame] {
        guard let i = image else { return [] }
        return i.loadedFrames
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        frames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SampleImageFrameTableViewCell", for: indexPath) as! SampleImageFrameTableViewCell
        cell.set(frame: frames[indexPath.row].frameControl, image: image?.cachedFrameImage(at: indexPath.row), index: indexPath.row, scale: image!.scale)
        return cell
    }
    
}

class SampleImageFrameTableViewCell: UITableViewCell {
    @IBOutlet weak var offsetLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var disposeLabel: UILabel!
    @IBOutlet weak var blendLabel: UILabel!
    
    @IBOutlet weak var renderedImageView: UIImageView!
    
    @IBOutlet weak var bgWidth: NSLayoutConstraint!
    @IBOutlet weak var bgHeight: NSLayoutConstraint!
    
    @IBOutlet weak var overlayWidth: NSLayoutConstraint!
    @IBOutlet weak var overlayHeight: NSLayoutConstraint!
    @IBOutlet weak var overlayTop: NSLayoutConstraint!
    @IBOutlet weak var overlayLeading: NSLayoutConstraint!
    
    @IBOutlet weak var frameCountLabel: UILabel!
    
    func set(frame: fcTL, image: CGImage?, index: Int, scale: CGFloat) {
        frameCountLabel.text = "#\(index)"
        
        offsetLabel.text = "{\(frame.xOffset), \(frame.yOffset)}"
        sizeLabel.text = "\(frame.width) x \(frame.height)"
        durationLabel.text = String(format: "%.3f", frame.duration) + " s"
        disposeLabel.text = frame.disposeOp.text
        blendLabel.text = frame.blendOp.text
        
        if let cgImage = image {
            let uiImage = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
            renderedImageView.image = uiImage
            let ratio = uiImage.size.aspectFitRatio(to: renderedImageView.bounds.size)
            let scaledSize = uiImage.size.aspectFit(to: renderedImageView.bounds.size)
            
            bgWidth.constant = scaledSize.width
            bgHeight.constant = scaledSize.height
            
            let scaledRenderSize = CGSize(width: CGFloat(frame.width) / scale / ratio, height: CGFloat(frame.height) / scale / ratio)
            let scaledOffset = CGPoint(x: CGFloat(frame.xOffset) / scale / ratio, y: CGFloat(frame.yOffset) / scale / ratio)
            
            let scaledOriginOffset = CGPoint(
                x: (renderedImageView.bounds.size.width - scaledSize.width) / 2,
                y: (renderedImageView.bounds.size.height - scaledSize.height) / 2
            )
            
            overlayLeading.constant = scaledOffset.x + scaledOriginOffset.x
            overlayTop.constant = scaledOffset.y + scaledOriginOffset.y
            overlayWidth.constant = scaledRenderSize.width
            overlayHeight.constant = scaledRenderSize.height
            
        } else {
            renderedImageView.image = nil
            bgWidth.constant = 0
            bgHeight.constant = 0
        }
        
        
    }
}

extension CGSize {
    func aspectFitRatio(to size: CGSize) -> CGFloat {
        max(width / size.width, height / size.height)
    }
    
    func aspectFit(to size: CGSize) -> CGSize {
        let ratio = aspectFitRatio(to: size)
        return .init(width: width / ratio, height: height / ratio)
    }
}

extension fcTL.DisposeOp {
    var text: String {
        switch self {
        case .none: return "None"
        case .background: return "Background"
        case .previous: return "Previous"
        }
    }
}

extension fcTL.BlendOp {
    var text: String {
        switch self {
        case .source: return "Source"
        case .over: return "Over"
        }
    }
}
