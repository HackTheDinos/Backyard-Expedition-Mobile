//
//  SubmissionReviewController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit
import Interstellar

class SubmissionReviewController: UIViewController {
    weak var submission: Submission?
    @IBOutlet weak var submitButton: UIButton!

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var photoCountLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Review", comment: "Review view title")

        submitButton.backgroundColor = (UIApplication.sharedApplication().delegate as! AppDelegate).blueColor
        submitButton.tintColor = UIColor.whiteColor()
        submitButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        submitButton.layer.cornerRadius = 5.0

        // XXX: this is not the correct approach for localization, but we're short on time before presentation
        switch submission?.photos.count ?? 0 {
        case 1:
            photoCountLabel.text = "\(submission?.photos.count ?? 0) photo"
        default:
            photoCountLabel.text = "\(submission?.photos.count ?? 0) photos"
        }

        previewImageView.clipsToBounds = true
        
        if let photoUrl = submission?.photos.first {
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
                .next { [weak self] image in
                    // update the cell with the image
                    print("got image data: \(image)")
                    self?.previewImageView.image = image
            }
            photoSignal.update(photoUrl)
        }
    }

}

extension SubmissionReviewController {
    @IBAction func submitButtonTapped(sender: AnyObject) {
        // save the submission file
        // TODO: update some app model with the entire list of submissions
        self.submission?.save(Submission.submissionDirectory(), completion: { result in
            switch result {
            case .Success(let url):
                print("successfully saved the submission: \(url)")
            case .Error(let error):
                print("error saving the submission: \(error)")
            }
        })
        // upload/email the data

        // fakin' it!
        let alert = UIAlertController(title: "Thank you!",
            message: "Your submission was uploaded. We'll review it and send an evaluation to the provided email address.\n\nGood luck!",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: { action in
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}