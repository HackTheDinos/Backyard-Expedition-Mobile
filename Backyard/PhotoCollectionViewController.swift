//
//  photoCollectionViewController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Interstellar

class PhotoCell: UICollectionViewCell {
    var imageView: UIImageView!

    override init(frame: CGRect) {
        imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        
        super.init(frame: frame)

        self.contentView.addSubview(imageView)
        imageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(snp_edges)
        }
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRectZero)
    }
}

class PhotoCollectionViewController: UIViewController {
    var collectionView: UICollectionView?
    weak var submission: Submission?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.title = NSLocalizedString("Photos", comment: "Photo view title")

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 90, height: 90) // overridden below.

        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.registerClass(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView!.backgroundColor = UIColor.whiteColor()

        self.view.addSubview(collectionView!)
        collectionView?.snp_makeConstraints(closure: { (make) -> Void in
            make.edges.equalTo(view.snp_edges)
        })
    }

    override func viewWillLayoutSubviews() {
        // adjust the cell layout
        if let collectionView = self.collectionView {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            let insets = layout.sectionInset
            let dimension = self.view.bounds.width - (insets.left + insets.right)
            layout.itemSize = CGSize(width: dimension, height: dimension)
        }
    }
}

extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return submission?.photos.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell // could use custom class here
        cell.backgroundColor = UIColor.grayColor()

        // TODO: add photo / thumbnail from submission
        if let photoUrl = submission?.photos[indexPath.row] {
            // load the photo async
            let photoSignal = Signal<NSURL>()
            photoSignal
            .ensure(Thread.background)
            .map { (url: NSURL) -> UIImage? in
                // load the file from disk, and return image data
                guard let data = NSData(contentsOfURL: url) else {
                    return nil
                }
                // really need to build in caching.
                return UIImage(data: data, scale: 0)
            }
            .ensure(Thread.main)
            .next { image in
                // update the cell with the image
                print("got image data: \(image)")
                cell.imageView.image = image
            }
            photoSignal.update(photoUrl)
        }

//        cell.textLabel?.text = "\(indexPath.section):\(indexPath.row)"
//        cell.imageView?.image = UIImage(named: "circle")
        
        return cell
    }


}
