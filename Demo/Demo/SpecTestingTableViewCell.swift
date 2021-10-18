//
//  SpecTestingTableViewCell.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/18.
//

import UIKit
import APNGKit

class SpecTestingTableViewCell: UITableViewCell {
    @IBOutlet weak var animatedImageView: APNGImageView! {
        didSet {
            animatedImageView.contentMode = .center
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        animatedImageView.image = nil
    }
    
    func setData(_ data: SpecCase) {
        titleLabel.text = "\(data.index). \(data.text.title)"
        detailLabel.text = data.text.detail
        
        animatedImageView.onDecodingFrameError.delegate(on: self) { (self, item) in
            if !item.canFallbackToDefaultImage {
                print("Decoded Error: \(item.error)")
                self.animatedImageView.staticImage = UIImage(named: "xmark.square")
            }
        }
        
        do {
            let image = try APNGImage(named: data.imageName)
            animatedImageView.image = image
        } catch {
            if case .imageError(.normalImageDataLoaded(let image)) = error.apngError {
                animatedImageView.staticImage = image
            } else {
                animatedImageView.staticImage = UIImage(named: "xmark.square")
                print("Error: \(error) at index: \(data.index)")
            }
        }
    }
}
