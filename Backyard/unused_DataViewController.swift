//
//  DataViewController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/21/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import UIKit
import Interstellar
import SnapKit

class DataViewController: UIViewController {

    @IBOutlet weak var dataLabel: UILabel!
    var dataObject: String = ""

    let cameraButtonSignal = Signal<UIControlEvents>()
    let photoLibraryButtonSignal = Signal<UIControlEvents>()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let cameraButton = UIButton(type:.System)
        cameraButton.setTitle(NSLocalizedString("Take Photo", comment: "Camera Button Title"),
            forState: .Normal)
        cameraButton.addTarget(self, action: "cameraButtonTapped:", forControlEvents: .TouchUpInside)

        let photoLibraryButton = UIButton(type: .System)
        photoLibraryButton.setTitle(NSLocalizedString("Photo Library", comment: "Photo library button title"),
            forState: .Normal)
        photoLibraryButton.addTarget(self, action: "photoLibraryButtonTapped:", forControlEvents: .TouchUpInside)

        self.view.addSubview(cameraButton)
        cameraButton.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(view)
        }
        self.view.addSubview(photoLibraryButton)
        photoLibraryButton.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(cameraButton)
            make.top.equalTo(cameraButton.snp_bottom).offset(10)
        }

        // TODO: could instead provide feedback when tapped if the camera is not available
        cameraButton.enabled = ImageCapture.isCameraAvailable()
        cameraButtonSignal
            .map {event in
                .Camera
            }
            .flatMap(ImageCapture(viewController: self).takePicture)
            .next { image in
                // here's the picture!
                print("got an image: \(image)")
            }
            .error { error in
                // the user is not really into taking pictures.
                print("got an error from ImageCapture: \(error)")
        }

        photoLibraryButton.enabled = ImageCapture.isPhotoLibraryAvailable()
        photoLibraryButtonSignal
            .map { controlEvents in
                .PhotoLibrary
            }
            .flatMap(ImageCapture(viewController: self).takePicture)
            .next { image in
                print("got an image from the library: \(image)")
            }
            .error { error in
                print("got an error from ImageCapture: \(error)")
            }

        if !ImageCapture.isAuthorizedForCamera() {
            print("not authorized for camera")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.dataLabel!.text = dataObject
    }


    func cameraButtonTapped(sender:UIButton?) -> () {
        // the specific event does not really matter
        cameraButtonSignal.update(.TouchUpInside)
    }
    func photoLibraryButtonTapped(sender:UIButton?) -> () {
        // the specific event does not really matter
        photoLibraryButtonSignal.update(.TouchUpInside)
    }
}

