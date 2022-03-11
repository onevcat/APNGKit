//
//  MultipleImagesViewController.swift
//  Demo-macOS
//
//  Created by Wang Wei on 2022/03/11.
//

import Cocoa
import APNGKit

class MultipleImagesViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {

    @IBOutlet weak var collectionView: NSCollectionView!
    
    static let availableImages: [APNGImage] = sampleImages.compactMap {
        try? APNGImage(named: $0)
    }
    
    var images: [APNGImage] = MultipleImagesViewController.availableImages
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(MultipleImageCollectionViewItem.self, forItemWithIdentifier: .init(rawValue: "MultipleImageCollectionViewItem"))
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .init(rawValue: "MultipleImageCollectionViewItem"), for: indexPath) as! MultipleImageCollectionViewItem
        item.setImage(images[indexPath.item])
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectItems(at: indexPaths)
        
        let item = collectionView.item(at: indexPaths.first!) as! MultipleImageCollectionViewItem
        try? item.animatedImageView.reset()
    }
    
    @IBAction func addImage(_ sender: Any) {
        let random = Int.random(in: 0 ..< MultipleImagesViewController.availableImages.count)
        images.append(MultipleImagesViewController.availableImages[random])
        
        let targets: Set<IndexPath> = [.init(item: images.count - 1, section: 0)]
        collectionView.insertItems(at: targets)
        collectionView.scrollToItems(at: targets, scrollPosition: .bottom)
    }
}


class MultipleImageCollectionViewItem: NSCollectionViewItem {
    var animatedImageView: APNGImageView!

    override func loadView() {
        view = NSView()
        let imageView = APNGImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        animatedImageView = imageView
        animatedImageView.layerContentsPlacement = .scaleProportionallyToFit
    }
    
    func setImage(_ image: APNGImage) {
        animatedImageView.image = image
    }
}
