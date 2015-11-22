//
//  SubmissionReviewController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit

class SubmissionReviewController: UIViewController {
    weak var submission: Submission?
    @IBOutlet weak var submitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Review", comment: "Review view title")
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
    }
}