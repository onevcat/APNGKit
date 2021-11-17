//
//  ViewController.swift
//  Demo-macOS
//
//  Created by Wang Wei on 2021/10/31.
//

import Cocoa
import APNGKit

class SamplesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var imageView: APNGImageView!
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageSizeLabel: NSTextField!
    @IBOutlet weak var imageDurationLabel: NSTextField!
    @IBOutlet weak var imageFrameCountLabel: NSTextField!
    
    @IBOutlet weak var infoView: NSStackView!
    @IBOutlet weak var previewLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SampleImageTableCell"), owner: self) as! NSTableCellView
        cell.textField?.stringValue = sampleImages[row]
        
        if let url = Bundle.main.url(forResource: sampleImages[row], withExtension: "apng") {
            cell.imageView?.image = NSImage(contentsOf: url)
        } else {
            cell.imageView?.image = NSImage(named: sampleImages[row])
        }
        
        return cell
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sampleImages.count
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0 else { return }
        infoView.isHidden = false
        previewLabel.isHidden = true
        
        let name = sampleImages[tableView.selectedRow]
        do {
            let image = try APNGImage(named: name)
            
            imageViewWidthConstraint.constant = image.size.width
            imageViewHeightConstraint.constant = image.size.height
            
            imageSizeLabel.stringValue = "\(image.size.width)x\(image.size.height) @ \(Int(image.scale))x"
            imageDurationLabel.stringValue = "-"
            imageFrameCountLabel.stringValue = "\(image.numberOfFrames)"
            
            image.onFramesInformationPrepared.delegate(on: self) { [weak image] (self, _) in
                guard let image = image else { return }
                switch image.duration {
                case .loadedPartial:
                    fatalError("All frames should be already loaded.")
                case .full(let d):
                    self.imageDurationLabel.stringValue = String(format: "%.3f", d) + " s"
                }
            }
            
            imageView.image = image
            
            
        } catch {
            if let i = error.apngError?.normalImage {
                imageView.staticImage = i
            }
            print(error)
        }
    }
}
