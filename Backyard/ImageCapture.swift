//
//  File.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import AVFoundation

import UIKit
import Interstellar

class ImageCapture: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var completion: (Result<UIImage> -> Void)?
    let vc: UIViewController

    init(viewController: UIViewController) {
        vc = viewController
    }

    func takePicture(source: UIImagePickerControllerSourceType, completion: (Result<UIImage>->Void)){
        self.completion = completion
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = source
        vc.presentViewController(picker, animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        let error = NSError(domain: "User did cancel", code: 401, userInfo: nil)
        completion?(Result.Error(error))
        picker.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        completion?(Result.Success(image))
        picker.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

// can we find out if we have permission to the photos/camera?
extension ImageCapture {
    static func isCameraAvailable () -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.Camera)
    }
    
    static func isPhotoLibraryAvailable () -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary)
    }

    // this is under-specified. the docs mention that each of the authorization statuses
    // have different meanings (eg. not known (yet) vs unable to change the settings vs denied)
    static func isAuthorizedForCamera () -> Bool {
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch authorizationStatus {
        case .Authorized:
            return true
        case .Denied,.Restricted,.NotDetermined:
            return false
        }
    }
}

extension ImageCapture {
    // this is a long running (though async) task.
    static func saveImage(source: (UIImage,NSURL), completion: (Result<NSURL>->Void)){
        if let data = UIImagePNGRepresentation(source.0) {
            let path = source.1.URLByAppendingPathExtension("png")
            do {
                try data.writeToURL(path, options: .AtomicWrite)
                completion(.Success(path))
            } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
                // if the path does not exist, then attempt to create it
                let fm = NSFileManager.defaultManager()
                do {
                    try fm.createDirectoryAtURL(source.1.URLByDeletingLastPathComponent!,
                        withIntermediateDirectories:true,
                        attributes: nil)

                    // try the save again
                    saveImage(source, completion: completion)
                } catch {
                    // just bail out
                    completion(.Error(error))
                }
            } catch let error {
                // otherwise, bail out
                completion(.Error(error))
            }
        } else {
            let error = NSError(domain: "net.robertcarlsen.backyard", code: 100, userInfo:[NSLocalizedDescriptionKey:"Unable to create data from the provided image"])
            completion(.Error(error))
        }
    }

    static func photosDirectory () -> NSURL {
        let fm = NSFileManager.defaultManager()
        let documentsURL = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        return documentsURL.URLByAppendingPathComponent("photos")
    }
}