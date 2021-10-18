//
//  SpecTestingExplanationViewController.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/18.
//

import UIKit
import APNGKit

class SpecTestingExplanationViewController: UIViewController {
    @IBOutlet weak var apngImageView: APNGImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    var data: SpecCase!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "\(data.index). \(data.text.title)"
        detailLabel.text = data.text.detail
        
        apngImageView.onDecodingFrameError.delegate(on: self) { (self, item) in
            if !item.canFallbackToDefaultImage {
                print("Decoded Error: \(item.error)")
                self.apngImageView.staticImage = UIImage(named: "xmark.square")
            }
            self.setError(item.error)
        }
        
        do {
            let image = try APNGImage(named: data.imageName)
            apngImageView.image = image
        } catch {
            self.setError(error)
            if case .imageError(.normalImageDataLoaded(let image)) = error.apngError {
                apngImageView.staticImage = image
            } else {
                apngImageView.staticImage = UIImage(named: "xmark.square")
                print("Error: \(error) at index: \(data.index)")
            }
        }
    }
    
    private func setError(_ error: Error) {
        errorLabel.isHidden = false
        errorLabel.text = "\(error)"
    }
}
