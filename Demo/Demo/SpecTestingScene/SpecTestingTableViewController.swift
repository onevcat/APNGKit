//
//  SpecTestingTableViewController.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/18.
//

import UIKit

class SpecCaseStore {
    private static var _cases: [SpecCase]?
    static var cases: [SpecCase] {
        if _cases == nil {
            let url = Bundle.main.url(forResource: "spec-cases", withExtension: "json")!
            let data = try! Data(contentsOf: url)
            let caseText = try! JSONDecoder().decode([SpecCase.Text].self, from: data)
            _cases = caseText.enumerated().map { (index, text) in
                .init(index: index, text: text)
            }
        }
        return _cases!
    }
}

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

struct SpecCase {
    
    struct Text: Decodable {
        let title: String
        let detail: String
    }
    
    let index: Int
    let text: Text
    
    var imageName: String {
        String(format: "%03d", index)
    }
}
