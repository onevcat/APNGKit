//
//  SplitViewController.swift
//  Demo-macOS
//
//  Created by Wang Wei on 2021/10/31.
//

import Cocoa

class SplitViewController: NSSplitViewController {
    
    weak var sidebarViewController: SidebarViewController!
    weak var detailViewController: NSViewController!
    
    var sampleViewController: SamplesViewController?
    var specTestViewController: SpecTestViewController?
    var multipleImagesViewController: MultipleImagesViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sidebarViewController = splitViewItems[0].viewController as? SidebarViewController
        detailViewController = splitViewItems[1].viewController
        
        sidebarViewController.onSelected.delegate(on: self) { (self, page) in
            self.switchToPage(page)
        }
    }
    
    func switchToPage(_ page: Page) {
        
        sampleViewController?.view.isHidden = true
        specTestViewController?.view.isHidden = true
        multipleImagesViewController?.view.isHidden = true
        
        switch page {
        case .samples:
            if sampleViewController == nil {
                let vc = NSStoryboard(name: "Main", bundle: .main).instantiateController(withIdentifier: .init("SamplesViewController")) as! SamplesViewController
                detailViewController.add(vc)
                sampleViewController = vc
            }
            print("Show sample")
            sampleViewController?.view.isHidden = false
        case .specTests:
            if specTestViewController == nil {
                let vc = NSStoryboard(name: "Main", bundle: .main).instantiateController(withIdentifier: .init("SpecTestViewController")) as! SpecTestViewController
                detailViewController.add(vc)
                specTestViewController = vc
            }
            print("Show spec")
            specTestViewController?.view.isHidden = false
        case .multipleImages:
            if multipleImagesViewController == nil {
                let vc = NSStoryboard(name: "Main", bundle: .main).instantiateController(withIdentifier: .init("MultipleImagesViewController")) as! MultipleImagesViewController
                detailViewController.add(vc)
                multipleImagesViewController = vc
            }
            print("Show multi")
            multipleImagesViewController?.view.isHidden = false
        }
    }
}

extension NSViewController {
    func add(_ child: NSViewController) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            child.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func remove() {
        view.removeFromSuperview()
        removeFromParent()
    }
}
