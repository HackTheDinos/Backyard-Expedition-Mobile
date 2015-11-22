//
//  SubmissionPhotosController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/22/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Interstellar

class SubmissionPhotosController: UIViewController {
    var submission: Submission? // this one owns it for the rest
    
    var photosViewController: PhotoCollectionViewController?
    @IBOutlet weak var addPhotoButton: UIButton!
    var nextButton: UIBarButtonItem!

    let getImageSignal = Signal<UIImagePickerControllerSourceType>()

    override func viewDidLoad() {
        super.viewDidLoad()

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
            .next { [weak self] image in
                // here's the picture!
                print("got an image: \(image)")

                // save it to the submission and update our photos controller
                if let imageBaseName = self?.submission?.recordId.UUIDString.stringByAppendingString("_\(NSUUID().UUIDString)") {
                    let saveSignal = Signal<(UIImage, NSURL)>()
                    saveSignal
                        .ensure(Thread.background)
                        .flatMap(ImageCapture.saveImage)
                        .ensure(Thread.main)
                        .next { [weak self] url in
                            print("finished saving image at url: \(url)")

                            self?.submission?.photos.append(url)
                            self?.photosViewController?.collectionView?.reloadData()
                        }
                        .error { error in
                            print("error saving image: \(error)")
                        }
                    let photoUrl = ImageCapture.photosDirectory().URLByAppendingPathComponent(imageBaseName)
                    saveSignal.update((image, photoUrl))
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
    }
}

extension SubmissionPhotosController {
    func nextButtonTapped(sender: UIBarButtonItem?) {
        // present the form view
        let formController = UIStoryboard.getViewController(identifier: "SubmissionForm") as! SubmissionFormController
        formController.submission = submission
        self.navigationController?.pushViewController(formController, animated: true)
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