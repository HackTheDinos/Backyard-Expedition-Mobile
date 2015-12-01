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
    private(set) var submissions = [Submission]()
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
    func addSubmission(submission: Submission) -> Result<Submission> {
        defer { submissionSignal.update(submissions.count) }

        submissions.append(submission)
        return .Success(submission)
    }

    func newSubmission() -> Result<Submission> {
        let submission = Submission()
        return addSubmission(submission)
    }

    func removeSubmission(submission: Submission) -> Result<Int> {
        defer { submissionSignal.update(submissions.count) }
        guard let index = submissions.indexOf(submission) else {
            let error = NSError(domain: "net.robertcarlsen.backyard",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "submission not found"] )
            return .Error(error)
        }

        let removedSubmission = submissions.removeAtIndex(index)
        // don't really care about the removed url, so map Result to the removed submission index
        return Submission.deleteSubmission(removedSubmission).map { _ in index }
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

    // not tested
    func deleteSubmissions(completion: (Result<Int> -> Void)) {
        let deleteSignal = Signal<[Submission]>()
        deleteSignal.ensure(Thread.background)
        .map {submissions in
            return submissions.map { Submission.deleteSubmission($0) }
        }
        .ensure(Thread.main)
        .next { completion(.Success($0.count)) }
        .error { completion(.Error($0)) }

        deleteSignal.update(submissions)
    }
}

