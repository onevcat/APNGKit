//
//  MultipleImageCollectionViewCell.swift
//  Demo
//
//  Created by Wang Wei on 2022/03/11.
//

import UIKit
import APNGKit

class MultipleImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var animatedImageView: APNGImageView! {
        didSet {
            animatedImageView.contentMode = .scaleAspectFit
        }
    }

    func setImage(_ image: APNGImage) {
        animatedImageView.image = image
    }
}
