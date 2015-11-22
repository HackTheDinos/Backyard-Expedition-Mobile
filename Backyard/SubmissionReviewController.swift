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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Review", comment: "Review view title")
    }
}