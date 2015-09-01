//
//  DetailViewController.swift
//  APNGKit
//
//  Created by Wei Wang on 15/8/30.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import APNGKit

class DetailViewController: UIViewController {

    var image: Image?
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var timingLabel: UILabel!
    
    @IBOutlet weak var imageView: APNGImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let path = image?.path {
            
            let start = CACurrentMediaTime()
            let apngImage: APNGImage?
            if path.containsString("@2x") {
                apngImage = APNGImage(named: (path as NSString).lastPathComponent)
            } else {
                apngImage = APNGImage(contentsOfFile: path, saveToCache: true)
            }
            let end = CACurrentMediaTime()
            
            imageView.image = apngImage
            imageView.startAnimating()
            
            timingLabel.text = "Loaded in: \((end - start) * 1000)ms"
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
