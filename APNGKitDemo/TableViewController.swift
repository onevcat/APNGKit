//
//  TableViewController.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/29.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import UIKit

struct Image {
    let path: String
    let description: String
}

class TableViewController: UITableViewController {

    var images = [[Image](), [Image]()]
    
    func loadData() {
        if let info = NSBundle.mainBundle().objectForInfoDictionaryKey("InitImages") as? [Dictionary<String, String>] {
            for dic in info {
                let name = dic["name"]
                if let path = NSBundle.mainBundle().pathForResource(name, ofType: "png"),
                    des = dic["description"] {
                    images[0].append(Image(path: path, description: des))
                }
            }
        }
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).last!
        let contents = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(documentPath)
        
        let pngFiles = contents.filter{ $0.hasSuffix(".png") }
        for f in pngFiles {
            images[1].append(Image(path: f, description: ""))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.shadowImage = nil
        loadData()

        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return images.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        cell.textLabel?.text = (images[indexPath.section][indexPath.row].path as NSString).lastPathComponent

        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Built-in"
        case 1: return "User created"
        default: return nil
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.section != 0
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            images[indexPath.section].removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showDetail" {
            if let cell = sender as? UITableViewCell,
              indexPath = tableView.indexPathForCell(cell) {
                (segue.destinationViewController as! DetailViewController).image = images[indexPath.section][indexPath.row]
            }
        }
        
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showCreate" {
            let alert = UIAlertController(title: nil, message: "Creating of APNG is supported yet.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            return false
        }
        
        return true
    }

}
