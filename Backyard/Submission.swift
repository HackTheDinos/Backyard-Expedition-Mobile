//
//  Submission.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Interstellar

enum FossilStatus {
    case Yes
    case No
    case Maybe
}

enum SubmissionKey: String {
    case RecordId = "recordKey"
    case FossilId = "fossilKey"
    case Date = "dateKey"
    case Email = "emailKey"
    case InquiryId = "inquiryId"
    case InquiryText = "inquiryText"
    case Location = "inquiryLocation"
    case Photos = "photosKey"
}


class Submission: NSObject, NSCoding {
    let recordId: NSUUID
    var date: NSDate

    var fossilId: String?
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
    private(set) var photos: [NSURL]

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

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(recordId, forKey: SubmissionKey.RecordId.rawValue)
        coder.encodeObject(fossilId, forKey: SubmissionKey.FossilId.rawValue)
        coder.encodeObject(date, forKey: SubmissionKey.Date.rawValue)
        coder.encodeObject(contactEmail, forKey: SubmissionKey.Email.rawValue)
        coder.encodeObject(inquiryId, forKey: SubmissionKey.InquiryId.rawValue)
        coder.encodeObject(inquiryText, forKey: SubmissionKey.InquiryText.rawValue)
        coder.encodeObject(inquiryLocation, forKey: SubmissionKey.Location.rawValue)
        coder.encodeObject(photos, forKey: SubmissionKey.Photos.rawValue)
    }

    convenience required init?(coder decoder: NSCoder) {
        guard let recordId = decoder.decodeObjectForKey(SubmissionKey.RecordId.rawValue) as? NSUUID else {
            return nil
        }
        self.init(recordId: recordId)
        fossilId = decoder.decodeObjectForKey(SubmissionKey.FossilId.rawValue) as? String
        contactEmail = decoder.decodeObjectForKey(SubmissionKey.Email.rawValue) as? String
        inquiryId = decoder.decodeObjectForKey(SubmissionKey.InquiryId.rawValue) as? String
        inquiryText = decoder.decodeObjectForKey(SubmissionKey.InquiryText.rawValue) as? String
        inquiryLocation = decoder.decodeObjectForKey(SubmissionKey.Location.rawValue) as? CLLocation
        photos = decoder.decodeObjectForKey(SubmissionKey.Photos.rawValue) as? [NSURL] ?? [NSURL]()
        date = decoder.decodeObjectForKey(SubmissionKey.Date.rawValue) as? NSDate ?? NSDate()
    }
}

extension Submission {
    static func submissionDirectory() -> NSURL {
        let fm = NSFileManager.defaultManager()
        let documentsURL = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        return documentsURL.URLByAppendingPathComponent("submissions")
    }

    static func loadSubmissions(source: NSURL, completion: (Result<[Submission]>->Void)) {
        let fm = NSFileManager.defaultManager()
        do {
            let urls = try fm.contentsOfDirectoryAtURL(Submission.submissionDirectory(),
                includingPropertiesForKeys: [],
                options: NSDirectoryEnumerationOptions(rawValue: 0))
            var submissions = [Submission]()
            for url in urls {
                if let data = NSData(contentsOfURL: url), submission = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Submission {
                    submissions.append(submission)
                }
            }
            completion(.Success(submissions))
        }
        catch {
            completion(.Error(error))
        }
    }

    static func deleteSubmission(submission: Submission) -> Result<NSURL> {
        // remove all the photos
        for photoUrl in submission.photos {
            submission.removePhoto(photoUrl, completion:{_ in})
        }

        // remove the submission url
        let path = self.submissionDirectory()
            .URLByAppendingPathComponent(submission.recordId.UUIDString)
            .URLByAppendingPathExtension("bin")
        do {
            let fm = NSFileManager.defaultManager()
            try fm.removeItemAtURL(path)
            return .Success(path)
        }
        catch {
            return .Error(error)
        }
    }

    func save(source: NSURL, completion: (Result<NSURL>->Void)){
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        let path = source
            .URLByAppendingPathComponent(self.recordId.UUIDString)
            .URLByAppendingPathExtension("bin")
        do {
            try data.writeToURL(path, options: .AtomicWrite)
            completion(.Success(path))
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
            // if the path does not exist, then attempt to create it
            let fm = NSFileManager.defaultManager()
            do {
                try fm.createDirectoryAtURL(source,
                    withIntermediateDirectories:true,
                    attributes: nil)

                // try the save again
                save(source, completion: completion)
            } catch {
                // just bail out
                completion(.Error(error))
            }
        } catch let error {
            // otherwise, bail out
            completion(.Error(error))
        }
    }

    // save the photo data to disk, update our photos array, then return the saved url
    func addPhotoData(source: UIImage, completion: (Result<NSURL> -> Void)) {
        // save it to the submission and update our photos controller
        let imageBaseName = self.recordId.UUIDString.stringByAppendingString("_\(NSUUID().UUIDString)")
        let saveSignal = Signal<(UIImage, NSURL)>()
        saveSignal
            .ensure(Thread.background)
            .flatMap(ImageCapture.saveImage)
            .ensure(Thread.main)
            .next { url in
                self.photos.append(url)
                completion(.Success(url))
                // todo: create a signal for photo set add/remove
            }
            .error { error in
                completion(.Error(error))
            }

        let photoUrl = NSURL(fileURLWithPath: imageBaseName, relativeToURL: ImageCapture.photosDirectory())
        saveSignal.update((source, photoUrl))
    }

    func removePhoto(source: NSURL, completion: (Result<NSURL> -> Void)) {
        if let index = photos.indexOf(source) {
            photos.removeAtIndex(index)

            let fm = NSFileManager.defaultManager()
            do {
                try fm.removeItemAtURL(source)
                completion(.Success(source))
            }
            catch {
                completion(.Error(error))
            }

        } else {
            let error = NSError(domain: "net.robertcarlsen.backyard", code: 404, userInfo: [NSLocalizedDescriptionKey: "photo url not found in submission"])
            completion(.Error(error))
        }
    }

    func loadPhoto (url: NSURL) -> Signal<UIImage?> {
        let photoSignal = Signal<NSURL>()
        defer { photoSignal.update(url) }
        return photoSignal
            .ensure(Thread.background)
            .flatMap { url in
                return NSURL(fileURLWithPath: url.relativeString!, relativeToURL: ImageCapture.photosDirectory())
            }
            .flatMap { (url: NSURL) -> UIImage? in
                // load the file from disk, and return image data
                guard let data = NSData(contentsOfURL: url) else {
                    return nil
                }
                // really need to build in caching.
                return UIImage(data: data, scale: 0)
            }
            .ensure(Thread.main)
    }
}
