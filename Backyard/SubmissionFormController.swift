//
//  SubmissionFormController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Eureka

enum RowTag: String {
    case InquiryId = "inquiryId"
    case InquiryLocation = "inquiryLocation"
    case InquiryContact = "inquiryContact"
    case InquiryText = "inquiryText"
}

class SubmissionFormController: FormViewController {
    weak var submission: Submission?
    var nextButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Information", comment: "Form view title")

        // add a next button (upper right bar), enabled only if at least one photo has been added
        nextButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: "Next button"),
            style: .Plain,
            target: self,
            action: "nextButtonTapped:")
        self.navigationItem.rightBarButtonItem = nextButton

        form
            +++ Section(NSLocalizedString("What do you think this is?", comment:"Form section title"))
            <<< PickerInlineRow<String>() { (row : PickerInlineRow<String>) -> Void in
                var options = [String]()
                options.append("Fossil")
                options.append("Egg")
                options.append("Plant")
                options.append("Tooth")
                options.append("Dinosaur")

                row.options = options.sort()
                row.options.append("Something else")

                row.title = "It might be..."
                row.value = row.options.first
                row.tag = RowTag.InquiryId.rawValue
            }
            .onChange { [weak self] row in
                self?.submission?.inquiryId = row.value
            }
            +++ Section(NSLocalizedString("Description", comment: "Form section title"))
            <<< TextAreaRow() { row in
                row.placeholder = "Tell us about your find..."
                row.tag = RowTag.InquiryText.rawValue
            }
            // this is not very efficient...should probably rework this.
            .onChange { [weak self] row in
                self?.submission?.inquiryText = row.value
            }
            +++ Section(NSLocalizedString("Where was it found?", comment: "Form section title"))
            <<< LocationRow(){ row in
                row.tag = "LocationRowTag"
                row.title = "Location"
                row.tag = RowTag.InquiryLocation.rawValue
                row.value = LocationManager.sharedInstance.currentLocation
            }
            .onChange { [weak self] row in
                self?.submission?.inquiryLocation = row.value
            }
            +++ Section(NSLocalizedString("Contact Information", comment: "Form section title"))
            <<< EmailRow() { row in
                row.placeholder = "Your email address"
                row.tag = RowTag.InquiryContact.rawValue
            }
            .onChange { [weak self] row in
                self?.submission?.contactEmail = row.value
            }

        LocationManager.sharedInstance.locationSignal.next { [weak self] (location) -> Void in
            if let locationRow = self!.form.rowByTag("LocationRowTag") as? LocationRow {
                locationRow.value = location
                locationRow.updateCell()
            }
        }
    }
}

extension SubmissionFormController {
    func nextButtonTapped(sender: UIBarButtonItem?) {
        // push the review page
        let reviewController = UIStoryboard.getViewController(identifier: "SubmissionReview") as! SubmissionReviewController
        reviewController.submission = submission
        self.navigationController?.pushViewController(reviewController, animated: true)
    }
}



