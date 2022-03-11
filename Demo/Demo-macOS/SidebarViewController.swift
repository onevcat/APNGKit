//
//  SidebarViewController.swift
//  Demo-macOS
//
//  Created by Wang Wei on 2021/10/31.
//

import Foundation
import Cocoa
import Delegate

enum Page: CaseIterable {
    case samples
    case specTests
    case multipleImages
    
    var title: String {
        switch self {
        case .samples: return "Samples"
        case .specTests: return "Spec Tests"
        case .multipleImages: return "Multiple Images"
        }
    }
    
    var imageName: String {
        switch self {
        case .samples: return "scribble.variable"
        case .specTests: return "checkmark.circle"
        case .multipleImages: return "mail.stack"
        }
    }
}

class SidebarViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    
    let onSelected = Delegate<Page, Void>()
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            let index = self.outlineView.row(forItem: Page.samples)
            self.outlineView.selectRowIndexes(.init(integer: index), byExtendingSelection: false)
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return Page.allCases[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let page = item as! Page
        let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) as! NSTableCellView
        cell.textField?.stringValue = page.title
        cell.imageView?.image = NSImage(systemSymbolName: page.imageName, accessibilityDescription: page.title)
        return cell
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        Page.allCases.count
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let page = Page.allCases[outlineView.selectedRow]
        onSelected(page)
    }

}
