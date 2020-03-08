//
//  TableViewController.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/29.
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

import UIKit
import APNGKit

struct Image {
    let path: String
    let description: String
}

class TableViewController: UITableViewController {

    var images = [[Image](), [Image]()]
    
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

    @IBAction func clearCache(_ sender: AnyObject) {
        // Normally, you do not need to call this. 
        // The cached memory will be released when receiving a memory warning or switched to background.
        APNGCache.defaultCache.clearMemoryCache()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.shadowImage = nil
        loadData()

        tableView.reloadData()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return images.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = (images[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row].path as NSString).lastPathComponent

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Built-in"
        case 1: return "User created"
        default: return nil
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return (indexPath as NSIndexPath).section != 0
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            images[(indexPath as NSIndexPath).section].remove(at: (indexPath as NSIndexPath).row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showDetail" {
            if let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) {
                (segue.destination as! DetailViewController).image = images[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            }
        }
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showCreate" {
            let alert = UIAlertController(title: nil, message: "Creating of APNG is supported yet.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return false
        }
        
        return true
    }

}
