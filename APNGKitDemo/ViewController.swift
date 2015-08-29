//
//  ViewController.swift
//  APNGKitDemo
//
//  Created by Wei Wang on 15/8/29.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import UIKit
import APNGKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var image: APNGImage?
        var imageView: APNGImageView?
        
        for i in 0 ..< 4 {
            for j in 0 ..< 4 {
                if let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("ball", ofType: "png")!) {
                    image = APNGImage(data: data)
                    print(image)
                    imageView = APNGImageView(image: image)
                    imageView!.frame = CGRect(x: j * 100, y: i * 100, width: 100, height: 100)
                    view.addSubview(imageView!)
                }
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

