//
//  SpecTestingTableViewController.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/18.
//

import UIKit

class SpecTestingTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SpecCaseStore.cases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpecTestingTableViewCell", for: indexPath) as! SpecTestingTableViewCell
        cell.setData(SpecCaseStore.cases[indexPath.row])
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showExplanation" {
            let vc = segue.destination as! SpecTestingExplanationViewController
            let index = tableView.indexPathForSelectedRow
            vc.data = SpecCaseStore.cases[index?.row ?? 0]
        }
    }
}
