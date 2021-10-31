//
//  SpecStore.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/31.
//

import Foundation

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
