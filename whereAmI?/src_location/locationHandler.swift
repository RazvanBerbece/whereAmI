//
//  server.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 24/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public class locationAnalysis {
    
    private var latitude : Double
    private var longitude : Double
    
    init() {
        self.latitude = 0.0
        self.longitude = 0.0
    }
    
    init(lat: Double, long: Double) {
        self.latitude = lat
        self.longitude = long
    }
    
    func setLat(lat: Double) {
        self.latitude = lat
    }
    
    func setLong(long: Double) {
        self.longitude = long
    }
    
    /* Getting Placemark object through reverse Geofencing */
    func reverseGeolocation(completion: @escaping (String) -> Void) {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: self.latitude, longitude: self.longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler:
            { placemarks, error -> Void in
                if error == nil {
                    /* Returning the city name via a completion handler */
                    if let cityName = placemarks?[0].locality {
                        completion(cityName)
                    }
                }
                else {
                 // An error occurred during geocoding.
                    completion("")
                }
        })
    }
}
