//
//  HomeViewController.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/22/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit


class HomeViewController: UINavigationController {
}

extension UIStoryboard {
    // note: the underlying method will raise if the identifier is not found
    class func getViewController(identifier identifier: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier(identifier)
    }
}