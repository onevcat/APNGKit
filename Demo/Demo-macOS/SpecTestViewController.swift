//
//  SpecTestViewController.swift
//  Demo-macOS
//
//  Created by Wang Wei on 2021/10/31.
//

import Cocoa
import APNGKit

class SpecTestViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
         SpecCaseStore.cases.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let spec = SpecCaseStore.cases[row]
        let cell: NSTableCellView
        if tableColumn?.identifier.rawValue == "ImageColumn" {
            cell = tableView.makeView(withIdentifier: .init("ImageCell"), owner: self) as! NSTableCellView
            (cell as! SpecTestImageCellView).setData(spec)
        } else {
            cell = tableView.makeView(withIdentifier: .init("DetailCell"), owner: self) as! NSTableCellView
            cell.textField?.stringValue = spec.text.title + "\n" + spec.text.detail
        }
        return cell
    }
    
}

class SpecTestImageCellView: NSTableCellView {
    @IBOutlet var animatedImageView: APNGImageView!
    
    func setData(_ data: SpecCase) {
        animatedImageView.onDecodingFrameError.delegate(on: self) { (self, item) in
            if !item.canFallbackToDefaultImage {
                print("Decoded Error: \(item.error)")
                self.animatedImageView.staticImage = NSImage(named: "xmark.square")
            }
        }
        animatedImageView.layer?.contentsGravity = .center
        do {
            let image = try APNGImage(named: data.imageName)
            animatedImageView.image = image
        } catch {
            if let normalImage = error.apngError?.normalImage {
                animatedImageView.staticImage = normalImage
            } else {
                animatedImageView.staticImage = NSImage(named: "xmark.square")
                print("Error: \(error) at index: \(data.index)")
            }
        }
    }
}
