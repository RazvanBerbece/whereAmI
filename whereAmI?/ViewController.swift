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
    
    /* Managers Initialisations */
    private let locationManager = CLLocationManager()
    private var locationAnalysisClass = locationAnalysis()
    private var geofenceManager = GeofencingManager()
    private var locationQueue = LocationList()
    private let textToSpeechManager = TextToSpeechManager()
    
    /* UIKit Components Variable Initialisation */
    @IBOutlet weak var labelLocationLong: UILabel!
    @IBOutlet weak var labelLocationLat: UILabel!
    @IBOutlet weak var labelCurrentCity: UILabel!
    @IBOutlet weak var labelNearestLocation: UILabel!
    
    /* Current location / testing objects as GeofenceLocation */
    private var currentLocation = GeofenceLocation()
    let newGeofenceLocation = GeofenceLocation(coords: CLLocation(latitude: 51.447, longitude: -0.238).coordinate, name: "Home")
    var appStarted : Bool = false
    
    /* Called at runtime, manages evrything related to the current location */
    /** Listening for locations and printing them as the current one changes */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        /* Updating labels with current coordinates */
        labelLocationLong.text = "\(locValue.longitude)"
        labelLocationLat.text = "\(locValue.latitude)"
        
        /* Setting class variables for the Analysis class */
        self.locationAnalysisClass.setLat(lat: locValue.latitude)
        self.locationAnalysisClass.setLong(long: locValue.longitude)
        
        /* Reverse geocoding & Change label to current City */
        self.locationAnalysisClass.reverseGeolocation(completion: {
            (result) -> Void in
            if result.isEmpty == false {
                DispatchQueue.main.async {
                    /* Setting the current location GeofenceLocation */
                    self.currentLocation.setCoords(coords: locValue)
                    self.currentLocation.setName(name: result)
                    self.currentLocation.setRadius(radius: 10)
                    
                    /* Checking if at start-up, user is already in a location */
                    if !self.appStarted {
                        for location in self.locationManager.monitoredRegions {
                            let circularArea = location as! CLCircularRegion
                            if distanceToLocation(destinationGeo: GeofenceLocation(coords: circularArea.center, name: circularArea.identifier), currentLocationGeo: self.currentLocation) < 100 {
                                self.textToSpeechManager.toSpeech(text: location.identifier, delay: 5)
                                DispatchQueue.main.async {
                                    self.labelNearestLocation.text = location.identifier
                                }
                            }
                        }
                        self.appStarted = true
                    }
                    
                    /* Setting the current city label */
                    self.labelCurrentCity.text = "\(result as String)"
                }
            }
        })
    }
    
    /* User entered CLRegion Area */
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.textToSpeechManager.toSpeech(text: "You have \(region.identifier) in your proximity.", delay: 5)
        self.labelNearestLocation.text = region.identifier
    }
    
    /* User exited CLRegion Area */
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        self.labelNearestLocation.text = "Calculating nearest point of interest ..."
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.textToSpeechManager.toSpeech(text: "Welcome!", delay: 5)
        
        /* Adding one location to be monitored for geofencing */
        geofenceManager.startMonitoring(location: newGeofenceLocation, locationManager: self.locationManager)
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        /* Selecting the desired accuracy of the location getter */
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // Init CLLocationManager
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
}

