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
    let newGeofenceLocation = GeofenceLocation(coords: CLLocation(latitude: 51.44, longitude: -0.23).coordinate, name: "Home")
    
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
                    /* Setting the current city label */
                    self.labelCurrentCity.text = "\(result as String)"
                }
            }
        })
        
        print("Current location : " + String(describing: self.currentLocation.getCoordinates()))
        print("Geofence : " + String(describing : self.newGeofenceLocation.getCoordinates()))
        print("Distance : " + String(describing: geofenceManager.distanceToLocation(destinationGeo: newGeofenceLocation, currentLocationGeo: self.currentLocation)))
        if geofenceManager.distanceToLocation(destinationGeo: self.newGeofenceLocation, currentLocationGeo: self.currentLocation) < 1100 {
            print("User in proximity of \(self.newGeofenceLocation.getName())")
            self.labelNearestLocation.text = self.newGeofenceLocation.getName()
            
            if self.locationQueue.isEmpty() {
                /* Adding current geofencing location to the queue */
                self.locationQueue.append(location: newGeofenceLocation.getName())
                textToSpeechManager.toSpeech(text: "Bogdanel sa ma sugi de pula")
            }
        }
        else {
            self.locationQueue.delete()
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
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

