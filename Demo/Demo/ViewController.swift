//
//  ViewController.swift
//  Demo
//
//  Created by Wang Wei on 2021/10/17.
//

import UIKit
import APNGKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let imageView = APNGImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        do {
            let image = try APNGImage(named: "over_none")
            imageView.image = image
        } catch {
            print("Error: \(error)")
        }
    }


}

