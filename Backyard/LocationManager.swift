//
//  LocationManager.swift
//  Backyard
//
//  Created by Robert Carlsen on 11/22/15.
//  Copyright © 2015 AMNH. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Interstellar

class LocationManager: NSObject {
    let locationSignal = Signal<CLLocation>()

    var currentLocation: CLLocation!
    var locationManager: CLLocationManager!

    static let sharedInstance = LocationManager()

    override init() {
        currentLocation = CLLocation(latitude: 40.7811, longitude: -73.9741)
        locationManager = CLLocationManager()

        super.init()
        locationManager.delegate = self
        getQuickLocationUpdate()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func getQuickLocationUpdate() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locations: \(locations)")
        currentLocation = locations.first
        locationSignal.update(currentLocation)
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("location did fail: \(error)")
    }
}