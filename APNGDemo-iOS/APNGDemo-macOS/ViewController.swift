//
//  ViewController.swift
//  APNGDemo-macOS
//
//  Created by WANG WEI on 2017/4/3.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
