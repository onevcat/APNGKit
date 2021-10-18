//
//  SampleImageTableViewController.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/18.
//

import UIKit

class SampleImageTableViewController: UITableViewController {
    static let images: [String] = [
        "elephant_apng@2x",
        "elephant_apng",
        "APNG-4D",
        "spinfox",
        "ball",
        "APNG-cube",
        "pyani",
        "malformed-size",
        "minimalAPNG",
        "over_none",
        "over_background",
        "over_previous"
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.images.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SampleImageTableViewCell", for: indexPath)
        cell.textLabel?.text = Self.images[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let detailViewController = segue.destination as! SampleImageDetailViewController
            detailViewController.imageName = Self.images[tableView.indexPathForSelectedRow!.row]
        }
    }
}
