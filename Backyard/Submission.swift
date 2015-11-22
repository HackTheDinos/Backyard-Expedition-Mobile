//
//  Submission.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import CoreLocation

enum FossilStatus {
    case Yes
    case No
    case Maybe
}

class Submission: NSObject {
    let recordId: NSUUID

    var fossilId: String?
    var date: NSDate?
    var contactEmail: String?

    var inquiryId: String?
    var inquiryText: String?
    var inquiryLocation: CLLocation?

    var evaluationId: String?
    var evaluationText: String?
    var evaluationStatus: FossilStatus?

    // local paths to the files in the documents directory
    // should have a limit of 5 (per museum request)
    // where should that limit be enforced?
    // also, the instructions ask that each photo be no larger than 500kB
    // should we compress on upload or storage?
    var photos: [NSURL]

    // create a new record with a generated record id
    convenience override init() {
        self.init(recordId: NSUUID())
    }

    // create a record for an existing record id
    init(recordId: NSUUID) {
        self.recordId = recordId
        photos = []
        date = NSDate()
        
        super.init()
    }
}