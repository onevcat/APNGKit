//
//  SampleImageDetailViewController.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/18.
//

import UIKit
import APNGKit
import Delegate

class SampleImageDetailViewController: UIViewController {
    var imageName: String?
    
    @IBOutlet weak var imageView: APNGImageView!
    
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    
    var settingViewController: SampleImageDetailSettingViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        guard let imageName = imageName else {
            return
        }
        
        do {
            imageView.onOnePlayDone.delegate(on: self) { (self, count) in
                print("Played: \(count)")
            }
            imageView.onAllPlaysDone.delegate(on: self) { (self, _) in
                print("Played Done!")
            }
            imageView.onFrameMissed.delegate(on: self) { (self, index) in
                print("Frame missed at index: \(index)")
            }
            
            let image = try APNGImage(named: imageName)
            imageView.image = image
            imageViewHeightConstraint.constant = image.size.height
            imageViewWidthConstraint.constant = image.size.width
            
            wrapSetting()
        } catch {
            imageView.staticImage = error.apngError?.normalImage
            print("Error: \(error)")
        }
    }
    
    private func wrapSetting() {
        settingViewController = (children.first { $0 is SampleImageDetailSettingViewController }) as? SampleImageDetailSettingViewController
        
        guard let image = imageView.image else {
            return
        }
        
        settingViewController.setup(with: image)
        
        settingViewController.onIntrinsicToggled.delegate(on: self) { (self, useIntrinsic) in
            if useIntrinsic {
                self.imageViewWidthConstraint.constant = image.size.width
                self.imageViewHeightConstraint.constant = image.size.height
            } else {
                self.imageViewWidthConstraint.constant = self.settingViewController!.setSizeWidth
                self.imageViewHeightConstraint.constant = self.settingViewController!.setSizeHeight
            }
        }
        
        settingViewController.onSetSizeChanged.delegate(on: self) { (self, size) in
            self.imageViewWidthConstraint.constant = size.width
            self.imageViewHeightConstraint.constant = size.height
        }
        
        settingViewController.onBackgroundToggled.delegate(on: self) { (self, showBackground) in
            self.imageView.backgroundColor = showBackground ? .yellow : .clear
        }
        
        settingViewController.onResetAnimationClicked.delegate(on: self) { (self, _) in
            do {
                try self.imageView.reset()
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFrames" {
            let dest = segue.destination as! SampleImageFrameViewController
            dest.image = imageView.image
        }
    }
}

class SampleImageDetailSettingViewController: UITableViewController {
    
    weak var image: APNGImage?
    
    @IBOutlet weak var imageSizeLabel: UILabel!
    @IBOutlet weak var setSizeWidthTextField: UITextField! {
        didSet { setSizeWidthTextField.isEnabled = false }
    }
    @IBOutlet weak var setSizeHeightTextField: UITextField! {
        didSet { setSizeHeightTextField.isEnabled = false }
    }
    @IBOutlet weak var setSizeView: UIView! {
        didSet { setSizeView.alpha = 0.5 }
    }
    @IBOutlet weak var frameCountLabel: UILabel!
    @IBOutlet weak var repeatCountLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var cacheStatusLabel: UILabel!
    
    var setSizeWidth: CGFloat = 0.0
    var setSizeHeight: CGFloat = 0.0
    
    let onIntrinsicToggled = Delegate<Bool, Void>()
    let onBackgroundToggled = Delegate<Bool, Void>()
    let onSetSizeChanged = Delegate<CGSize, Void>()
    let onResetAnimationClicked = Delegate<(), Void>()
    
    func setup(with image: APNGImage) {
        self.image = image
        setSizeWidth = image.size.width
        setSizeHeight = image.size.height
        
        imageSizeLabel.text = "\(Int(image.size.width)) x \(Int(image.size.height)) @\(Int(image.scale))x"
        setSizeWidthTextField.text = "\(Int(image.size.width))"
        setSizeHeightTextField.text = "\(Int(image.size.height))"
        cacheStatusLabel.text = image.cachePolicy == .cache ? "Yes" : "No"
        
        frameCountLabel.text = String(image.numberOfFrames)
        if let num = image.numberOfPlays {
            repeatCountLabel.text = String(num)
        } else {
            repeatCountLabel.text = "Forever"
        }
        
        image.onFramesInformationPrepared.delegate(on: self) { (self, _) in
            guard let i = self.image else { return }
            switch i.duration {
            case .loadedPartial:
                fatalError("All frames should be already loaded.")
            case .full(let d):
                self.durationLabel.text = String(format: "%.3f", d) + " s"
            }
        }
    }
    
    @IBAction func intrinsicToggled(_ sender: UISwitch) {
        onIntrinsicToggled(sender.isOn)
        
        guard let image = image else { return }
        if sender.isOn {
            setSizeWidthTextField.text = "\(Int(image.size.width))"
            setSizeWidthTextField.isEnabled = false
            setSizeHeightTextField.text = "\(Int(image.size.height))"
            setSizeHeightTextField.isEnabled = false
            setSizeView.alpha = 0.5
        } else {
            setSizeWidthTextField.isEnabled = true
            setSizeHeightTextField.isEnabled = true
            setSizeView.alpha = 1.0
        }
    }
    
    @IBAction func backgroundColorToggled(_ sender: UISwitch) {
        onBackgroundToggled(sender.isOn)
    }
    
    @IBAction func resetAnimation(_ sender: Any) {
        onResetAnimationClicked()
    }
    
    @IBAction func sizeEditEnded(_ sender: Any) {
        guard let widthText = setSizeWidthTextField.text,
              let width = Int(widthText),
              let heightText = setSizeHeightTextField.text,
              let height = Int(heightText)
        else {
            return
        }
        onSetSizeChanged(.init(width: width, height: height))
    }
}

extension SampleImageDetailSettingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
