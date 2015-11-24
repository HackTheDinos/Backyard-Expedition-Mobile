//
//  AppModel.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/23/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import Interstellar

class AppModel {
    var submissions = [Submission]()
    var submissionSignal = Signal<Int>() // fired when submissions have been update. contains the current count.

    init() {
        // load submissions
        loadSubmissions { result in
            switch result {
            case let .Success(submissions):
                self.submissions = submissions
                self.submissionSignal.update(submissions.count)
            default: break
            }
        }
    }
}

extension AppModel {
    func submissionsByDate(newestFirst desc: Bool = true) -> [Submission]{
        return submissions.sort { ($0.date.compare($1.date) == NSComparisonResult.OrderedDescending) == desc }
    }
}
extension AppModel {
    func loadSubmissions(completion:(Result<[Submission]> -> Void)){
        let loadSubmissionSignal = Signal<NSURL>()
        loadSubmissionSignal
            .ensure(Thread.background)
            .flatMap(Submission.loadSubmissions)
            .ensure(Thread.main)
            .map { submissions -> [Submission] in
                print("loaded submissions: \(submissions)")
                return submissions
            }
            .next { submissions in
                completion(.Success(submissions))
            }
            .error { error in
                print("there was an error loading the submissions: \(error)")
                completion(.Error(error))
            }
        loadSubmissionSignal.update(Submission.submissionDirectory())
    }

    // not implemented
    func deleteSubmissions() {
        //        .map {submissions in
        //            for submission in submissions {
        //                let result = Submission.deleteSubmission(submission)
        //                switch result {
        //                case .Error(let error):
        //                    print("error deleting the submission: \(error)")
        //                case .Success(let url):
        //                    print("deleted the submission: \(url)")
        //                }
        //            }
        //        }
    }
}