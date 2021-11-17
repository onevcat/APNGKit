//
//  SampleImageTableViewController.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/18.
//

import UIKit

class SampleImageTableViewController: UITableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleImages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SampleImageTableViewCell", for: indexPath)
        cell.textLabel?.text = sampleImages[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let detailViewController = segue.destination as! SampleImageDetailViewController
            detailViewController.imageName = sampleImages[tableView.indexPathForSelectedRow!.row]
        }
    }
}
