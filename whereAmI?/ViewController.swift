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
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var appStarted : Bool = false
    
    /* Managers Initialisations */
    private let locationManager = CLLocationManager()
    private var locationAnalysisClass = locationAnalysis()
    private var geofenceManager = GeofencingManager()
    private var locationQueue = LocationList()
    private let textToSpeechManager = Speaker()
    private let clientCallManager = Client()
    
    /* UIKit Components Variable Initialisation */
    @IBOutlet weak var labelLocationLong: UILabel!
    @IBOutlet weak var labelLocationLat: UILabel!
    @IBOutlet weak var labelCurrentCity: UILabel!
    @IBOutlet weak var labelNearestLocation: UILabel!
    @IBOutlet weak var headerIcon: UILabel!
    
    @IBOutlet weak var viewMap: MKMapView!
    
    /* Current location / testing objects as GeofenceLocation */
    private var currentLocation = GeofenceLocation()
    
    /* Other Variables */
    let newGeofenceLocation = GeofenceLocation(coords: CLLocation(latitude: 51.447342409128, longitude: -0.238871354418).coordinate, name: "Home")
    let newGeofenceLocation2 = GeofenceLocation(coords: CLLocation(latitude: 51.447375147473, longitude: -0.238789905617).coordinate, name: "Garden")
    
    /* Called at runtime, manages evrything related to the current location */
    /** Listening for locations and printing them as the current one changes */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        /* Updating labels with current coordinates (12 decimal places) */
        labelLocationLong.text = String(format: "%.12f", locValue.longitude)
        labelLocationLat.text = String(format: "%.12f", locValue.latitude)
        
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
                    if !self.appStarted {
                        self.textToSpeechManager.toSpeech("You are in \(result)")
                        /* Checking if at start-up, user is already in a location */
                        for location in self.locationManager.monitoredRegions {
                            let circularArea = location as! CLCircularRegion
                            if distanceToLocation(destinationGeo: GeofenceLocation(coords: circularArea.center, name: circularArea.identifier), currentLocationGeo: self.currentLocation) < 10 {
                                self.textToSpeechManager.toSpeech(location.identifier)
                                DispatchQueue.main.async {
                                    self.labelNearestLocation.text = location.identifier
                                }
                            }
                            break
                        }
                        self.appStarted = true
                    }
                }
            }
        })
    }
    
    /* User entered CLRegion Area */
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered a region.")
        self.textToSpeechManager.toSpeech("You have \(region.identifier) in your proximity")
        self.labelNearestLocation.text = region.identifier
    }
    
    /* User exited CLRegion Area */
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited a region.")
        self.textToSpeechManager.toSpeech("You have left \(region.identifier) in your proximity")
        self.labelNearestLocation.text = "Calculating nearest point of interest ..."
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("The monitored regions are: \(manager.monitoredRegions)")
    }
    
    /* Overlaying Methodology */
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var circleRenderer = MKCircleRenderer()
        if let overlay = overlay as? MKCircle {
            circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.fillColor = UIColor.red
            circleRenderer.alpha = 0.1
        }
        return circleRenderer
    }
    
    func addRadiusCircle(location: CLLocation, radius: Double){
        self.viewMap.delegate = self
        var circle = MKCircle(center: location.coordinate, radius: radius as CLLocationDistance)
        self.viewMap.addOverlay(circle)
    }
    /* ----- END OF OVERLAYING METHODS ----- */
    
    
    override func viewDidLoad() {
        
        self.clientCallManager.getCoordinatesFromAPI(completion: {
            (data) in
            switch data.isEmpty {
            case true:
                print("The data package seems to be empty.")
            case false:
                let jsonString = String(data: data, encoding: .utf8)
                let jsonData = jsonString!.data(using: .utf8)
                if let json = try? JSON(data: jsonData!)
                {
                    var longs : [String] = []
                    var lats : [String] = []
                    var names : [String] = []
                    // If json is .Dictionary
                    for (key, subJson):(String, JSON) in json {
                        longs.append(String(describing: subJson["longitude"]))
                        lats.append(String(describing: subJson["latitude"]))
                        names.append(String(describing: subJson["name"]))
                    }
                    for i in 0...longs.count-1 {
                        
                        if (Double(lats[i]) == nil || Double(longs[i]) == nil || names[i].isEmpty) {
                            continue
                        }
                        
                        let geofenceObj = GeofenceLocation(coords: CLLocationCoordinate2D(latitude: Double(lats[i])!, longitude: Double(longs[i])!), name: names[i])
                        self.geofenceManager.startMonitoring(location: geofenceObj, locationManager: self.locationManager)
                        self.addRadiusCircle(location: CLLocation(latitude: Double(lats[i])!, longitude: Double(longs[i])!), radius: 1500)
                        
                    }
                }
            }
        })
        
        super.viewDidLoad()
        self.textToSpeechManager.toSpeech("Welcome!")
        self.locationManager.startMonitoring(for: self.geofenceManager.addRegion(with: self.newGeofenceLocation))
        
        self.headerIcon.font = UIFont.fontAwesome(ofSize: 25, style: .brands)
        self.headerIcon.text = String.fontAwesomeIcon(name: .apple)
        
        /* Adding one location to be monitored for geofencing */
        geofenceManager.startMonitoring(location: newGeofenceLocation, locationManager: self.locationManager)
        geofenceManager.startMonitoring(location: newGeofenceLocation2, locationManager: self.locationManager)
        self.addRadiusCircle(location: CLLocation(latitude: newGeofenceLocation.getCoordinates().latitude, longitude: newGeofenceLocation.getCoordinates().longitude), radius: 3)
        self.addRadiusCircle(location: CLLocation(latitude: newGeofenceLocation2.getCoordinates().latitude, longitude: newGeofenceLocation2.getCoordinates().longitude), radius: 5)
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        /* Selecting the desired accuracy of the location getter */
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // Init CLLocationManager
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        //Zoom to user location
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
            viewMap.setRegion(viewRegion, animated: false)
        }
        
    }
    
}
