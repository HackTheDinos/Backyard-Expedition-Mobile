//
//  SubmissionPhotosController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/22/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

import SnapKit
import Interstellar

class SubmissionPhotosController: UIViewController {
    var submission: Submission? // this one owns it for the rest
    
    var photosViewController: PhotoCollectionViewController?
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var noPhotosPlaceholderView: UIView!
    var nextButton: UIBarButtonItem!
    var cancelButton: UIBarButtonItem!

    let getImageSignal = Signal<UIImagePickerControllerSourceType>()

    override func viewDidLoad() {
        super.viewDidLoad()

        addPhotoButton.backgroundColor = (UIApplication.sharedApplication().delegate as! AppDelegate).blueColor
        addPhotoButton.tintColor = UIColor.whiteColor()
        addPhotoButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        addPhotoButton.layer.cornerRadius = 5.0

        self.title = NSLocalizedString("Add Photos", comment: "Photo controller title")

        // add the photo browser
        if let photosViewController = UIStoryboard.getViewController(identifier: "PhotoCollection") as? PhotoCollectionViewController {
            self.photosViewController = photosViewController
            photosViewController.submission = submission

            photosViewController.willMoveToParentViewController(self)
            self.view.insertSubview(photosViewController.view, belowSubview:addPhotoButton)
            photosViewController.didMoveToParentViewController(self)

            photosViewController.view.snp_makeConstraints(closure: { (make) -> Void in
                make.width.equalTo(view)
                make.top.equalTo(snp_topLayoutGuideBottom)
                make.bottom.equalTo(snp_bottomLayoutGuideTop)
            })
        }

        // configure add photo button
        addPhotoButton.addTarget(self, action: "addPhotoTapped:", forControlEvents: .TouchUpInside)
        getImageSignal
            .flatMap(ImageCapture(viewController: self).takePicture)
            .flatMap(self.submission!.addPhotoData)
            .next { [weak self] url in
                print("finished saving image at url: \(url)")

                if let index = self?.submission?.photos.endIndex {
                    self?.photosViewController?.collectionView?.insertItemsAtIndexPaths([NSIndexPath(forRow: index - 1, inSection: 0)])
                }

                if let isHidden = self?.noPhotosPlaceholderView.hidden where isHidden == false {
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        self?.noPhotosPlaceholderView.alpha = 0
                        }, completion: { (result) -> Void in
                            self?.noPhotosPlaceholderView.hidden = true
                            self?.noPhotosPlaceholderView.alpha = 1
                    })
                }
                switch self?.submission?.photos.count ?? 0 {
                case 0:
                    self?.addPhotoButton.setTitle(NSLocalizedString("Add Photo", comment: "Add photo button"), forState: .Normal)
                    self?.addPhotoButton.enabled = true
                    self?.nextButton.enabled = true
                case 1..<5:
                    self?.addPhotoButton.setTitle(NSLocalizedString("Add More Photos", comment: "Add photo button"), forState: .Normal)
                    self?.addPhotoButton.enabled = true
                    self?.nextButton.enabled = true
                default:
                    self?.addPhotoButton.setTitle(NSLocalizedString("Enough Photos", comment: "Add photo button"), forState: .Normal)
                    self?.addPhotoButton.enabled = false
                }
            }
            .error { error in
                // the user is not really into taking pictures.
                print("got an error from ImageCapture: \(error)")
        }

        // add a next button (upper right bar), enabled only if at least one photo has been added
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: "Next button"),
            style: .Plain,
            target: self,
            action: "nextButtonTapped:")
        self.navigationItem.rightBarButtonItem = nextButton

        nextButton.enabled = false
        if let submission = self.submission where submission.photos.count > 0 {
            noPhotosPlaceholderView.hidden = true
            nextButton.enabled = true
        }

        cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonTapped:")
        self.navigationItem.leftBarButtonItem = cancelButton
    }
}

extension SubmissionPhotosController {
    func nextButtonTapped(sender: UIBarButtonItem?) {
        // present the form view
        let formController = UIStoryboard.getViewController(identifier: "SubmissionForm") as! SubmissionFormController
        formController.submission = submission
        self.navigationController?.pushViewController(formController, animated: true)
    }

    func cancelButtonTapped(sender: UIBarButtonItem?) {
        if self.submission?.photos.count > 0 {
            // present an alert to confirm
            let alert = UIAlertController(title: NSLocalizedString("Remove Submission", comment: "Cancel alert title"),
                message: NSLocalizedString("Are you sure you would like to delete this submission?", comment: "Cancel alert message"),
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { [weak self] action in
                if let submission = self?.submission {
                    Submission.deleteSubmission(submission) // NOTE: this deletes the backing store, not the in-memory object.
                    self?.submission = nil
                }
                self?.navigationController?.popViewControllerAnimated(true)
                }))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    func addPhotoTapped(sender: UIButton?) {
        if ImageCapture.isCameraAvailable() && ImageCapture.isPhotoLibraryAvailable() {
            // present an action sheet if both photo library and camera are available
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Photo Library", comment: "Add photo option"),
                style: .Default, handler: { [unowned self] alertAction in
                    self.getImageSignal.update(.PhotoLibrary)
            }))
            actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Take Photo", comment: "Add photo option"),
                style: .Default, handler: { [unowned self] alertAction in
                    self.getImageSignal.update(.Camera)
                }))
            actionSheet.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "cancel action"), style: .Cancel, handler: nil))

            self.presentViewController(actionSheet, animated: true, completion: nil)

        } else if ImageCapture.isCameraAvailable() {
            // otherwise, just show the permitted type
            getImageSignal.update(.Camera)

        } else if ImageCapture.isPhotoLibraryAvailable() {
            // otherwise, just show the permitted type
            getImageSignal.update(.PhotoLibrary)
            
        } else {
            // if no types are available, the show an alert about permission.
            let appTitle = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String ?? "this app"
            let alert = UIAlertController(title: NSLocalizedString("No Photo Sources", comment: "Add photo alert"),
                message: "Ensure that \(appTitle) is permitted to use the camera and photo library:\n\nSettings > Privacy > Camera\nSettings > Privacy > Photos",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}