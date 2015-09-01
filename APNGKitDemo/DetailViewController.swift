//
//  DetailViewController.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/30.
//  Copyright © 2015年 OneV's Den. All rights reserved.
//

import UIKit
import APNGKit

class DetailViewController: UIViewController {

    var image: Image?
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var imageView: APNGImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let path = image?.path {
            let apngImage: APNGImage?
            if path.containsString("@2x") {
                apngImage = APNGImage(named: (path as NSString).lastPathComponent)
            } else {
                apngImage = APNGImage(contentsOfFile: path, saveToCache: true)
            }
            
            imageView.image = apngImage
            imageView.startAnimating()
                
            textLabel.text = image!.description
                
            title = (path as NSString).lastPathComponent
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
