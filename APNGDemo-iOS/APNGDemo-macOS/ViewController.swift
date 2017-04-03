//
//  ViewController.swift
//  APNGDemo-macOS
//
//  Created by WANG WEI on 2017/4/3.
//  Copyright © 2017年 OneV's Den. All rights reserved.
//

import Cocoa
import APNGKit

struct Image {
    let path: String
    let description: String
}

class ViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    var images = [[Image](), [Image]()]
    
    @IBOutlet weak var apngImageView: APNGImageView!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    
    func loadData() {
        if let info = Bundle.main.object(forInfoDictionaryKey: "InitImages") as? [Dictionary<String, String>] {
            for dic in info {
                let name = dic["name"]
                if let path = Bundle.main.path(forResource: name, ofType: "apng"),
                    let des = dic["description"] {
                    images[0].append(Image(path: path, description: des))
                    
                }
            }
        }
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
        let contents = try! FileManager.default.contentsOfDirectory(atPath: documentPath)
        
        let pngFiles = contents.filter{ $0.hasSuffix(".png") }
        for f in pngFiles {
            images[1].append(Image(path: f, description: ""))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.rowHeight = 30
        loadData()
        tableView.reloadData()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return images[0].count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "imageNameCell", owner: nil) as! NSTableCellView
        cell.textField?.stringValue = NSString(string: images[0][row].path).lastPathComponent
        return cell
    }
}

extension ViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        let path = images[0][row].path
        
        let image = APNGImage(contentsOfFile: path, saveToCache: true, progressive: true)!
        
        imageViewHeight.constant = imageWidth.constant * (image.size.height / image.size.width)
        
        apngImageView.image = image
        apngImageView.startAnimating()
    }
}
