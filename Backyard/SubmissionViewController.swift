//
//  SubmissionViewController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore


/// Entry point for a new submission
class SubmissionViewController: UIViewController {
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var finePrintLabel: UILabel!

    var listBarButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Specimen", comment: "Submission view title")

        // this is ugly...but I haven't had time to make a nice styling class
        getStartedButton.backgroundColor = UIColor.appBlueColor()
        getStartedButton.tintColor = UIColor.whiteColor()
        getStartedButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)
        getStartedButton.layer.cornerRadius = 5.0
        getStartedButton.addTarget(self, action: "getStartedTapped:", forControlEvents: .TouchUpInside)

        listBarButton = UIBarButtonItem(title: "List", style: .Plain, target: self, action: "listButtonTapped:")
        self.navigationItem.rightBarButtonItem = listBarButton
    }
}

extension SubmissionViewController {
    func getStartedTapped(sender: UIButton?) {
        // present the photos controller...with a new submission
        let photoController = UIStoryboard.getViewController(identifier: "SubmissionPhotos") as! SubmissionPhotosController
        switch AppDelegate.currentAppModel().newSubmission() {
        case let .Success(submission):
            photoController.submission = submission
            self.navigationController?.pushViewController(photoController, animated: true)
        case let .Error(error):
            print("unable to create new submission: \(error)")
        }
    }

    func listButtonTapped(sender: UIBarButtonItem?) {
        let listController = ListController()
        self.navigationController?.pushViewController(listController, animated: true)
    }
}