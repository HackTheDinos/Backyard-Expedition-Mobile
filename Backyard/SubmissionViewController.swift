//
//  SubmissionViewController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit

// TODO: need to catch this back button and present confirmation dialog
// and delete any assets if left.

/// Entry point for a new submission
class SubmissionViewController: UIViewController {
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var finePrintLabel: UILabel!

    override func viewDidLoad() {
        self.title = NSLocalizedString("Specimen Submission", comment: "Submission view title")
        // TODO: localize each of the user-facing elements

        getStartedButton.addTarget(self, action: "getStartedTapped:", forControlEvents: .TouchUpInside)
    }
}

extension SubmissionViewController {
    func getStartedTapped(sender: UIButton?) {
        // need to create a new submission instance
        // and pass it into the next controller.

        // present the photos controller...
        let photoController = UIStoryboard.getViewController(identifier: "SubmissionPhotos") as! SubmissionPhotosController
        photoController.submission = Submission()
        
        self.navigationController?.pushViewController(photoController, animated: true)
    }
}