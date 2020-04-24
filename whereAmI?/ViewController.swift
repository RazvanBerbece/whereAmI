//
//  ViewController.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 24/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FontAwesome_swift

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    @IBOutlet weak var labelLocationLong: UILabel!
    @IBOutlet weak var labelLocationLat: UILabel!
    
    /** Listening for locations and printing them as the current one changes */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        labelLocationLong.text = "\(locValue.longitude)"
        labelLocationLat.text = "\(locValue.latitude)"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        // Init CLLocationManager
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
    }


}

