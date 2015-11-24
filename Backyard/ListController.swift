//
//  ListController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/24/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit

class SubmissionCell: UICollectionViewCell {
    var imageView: UIImageView!
    var dateLabel: UILabel!

    override init(frame: CGRect) {
        imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true

        dateLabel = UILabel()
        dateLabel.text = "<date>"
        dateLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        dateLabel.sizeToFit()

        super.init(frame: frame)

        self.contentView.addSubview(imageView)
        self.contentView.addSubview(dateLabel)

        // something is messed up here.
        imageView.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(imageView.snp_width)
            make.leading.equalTo(snp_leadingMargin)
            make.trailing.equalTo(snp_trailingMargin)
            make.top.equalTo(snp_topMargin)
        }
        dateLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(snp_leadingMargin)
            make.trailing.equalTo(snp_trailingMargin)
            make.bottom.equalTo(snp_bottomMargin)
            make.top.equalTo(imageView.snp_bottom)
        }
    }

    required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame: CGRectZero)
    }
}


class ListController: UIViewController {
    weak var appModel = AppDelegate.currentAppModel()
    var collectionView: UICollectionView!

    private let formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Submissions", comment: "Submission list title")

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 90, height: 120) // overridden in viewWillLayoutSubviews

        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(SubmissionCell.self, forCellWithReuseIdentifier: "SubmissionCell")
        collectionView.backgroundColor = UIColor.whiteColor()

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
            let dimension = ceil(self.view.bounds.width/2) - (insets.left + insets.right)
            let dateLabelHeight:CGFloat = 20.0
            layout.itemSize = CGSize(width: dimension, height: dimension + dateLabelHeight)
        }
    }
}

extension ListController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appModel?.submissions.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SubmissionCell", forIndexPath: indexPath) as! SubmissionCell
        if let submission = appModel?.submissionsByDate()[indexPath.row] {
            cell.dateLabel.text = formatter.stringFromDate(submission.date)
            if let photoUrl = submission.photos.first {
                submission.loadPhoto(photoUrl).next { image in
                    cell.imageView.image = image
                }
            }
        }
        return cell
    }
}