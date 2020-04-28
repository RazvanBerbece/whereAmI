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
    @IBOutlet weak var labelMonitoredRegions: UILabel!
    
    @IBOutlet weak var viewMap: MKMapView!
    
    /* Current location / testing objects as GeofenceLocation */
    private var currentLocation = GeofenceLocation()
    private var lastCheckedRegionName : String = ""
    
    /* Other Variables */
    let newGeofenceLocation = GeofenceLocation(coords: CLLocation(latitude: 51.447342409128, longitude: -0.238871354418).coordinate, name: "Home")
    let newGeofenceLocation2 = GeofenceLocation(coords: CLLocation(latitude: 51.447375147473, longitude: -0.238789905617).coordinate, name: "Garden")
    
    /* Called at runtime, manages evrything related to the current location */
    /** Listening for locations and printing them as the current one changes */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        /* Updating labels with current coordinates (12 decimal places) */
        labelLocationLong.text = String(format: "%.15f", locValue.longitude)
        labelLocationLat.text = String(format: "%.15f", locValue.latitude)
        
        /* Setting class variables for the Analysis class */
        self.locationAnalysisClass.setLat(lat: locValue.latitude)
        self.locationAnalysisClass.setLong(long: locValue.longitude)
        
        /* Reverse geocoding & Change label to current City */
        self.locationAnalysisClass.reverseGeolocation(completion: {
            (result) -> Void in
            if result.isEmpty == false {
                /* Setting the current location GeofenceLocation */
                self.currentLocation.setCoords(coords: locValue)
                self.currentLocation.setName(name: result)
                self.currentLocation.setRadius(radius: 7.5)
                
                /* Setting the current city label */
                self.labelCurrentCity.text = "\(result as String)"
                if !self.appStarted {
                    self.textToSpeechManager.toSpeech("You are in \(result)")
                    
                    for location in self.locationManager.monitoredRegions {
                        print("--------- \(location) ---------")
                        let circularArea = location as! CLCircularRegion
                        if circularArea.contains(self.currentLocation.getCoordinates()) {
                            if (distanceToLocation(destinationGeo: GeofenceLocation(coords: circularArea.center, name: circularArea.identifier), currentLocationGeo: self.currentLocation) < 3.5) {
                                    self.labelNearestLocation.text = location.identifier
                                    self.textToSpeechManager.toSpeech(location.identifier)
                                    self.lastCheckedRegionName = circularArea.identifier
                            }
                            break
                        }
                    }
                    
                    self.appStarted = true
                }
            }
        })
        
        for location in self.locationManager.monitoredRegions {
            let circularArea = location as! CLCircularRegion
            if circularArea.contains(self.currentLocation.getCoordinates()) && circularArea.identifier != self.lastCheckedRegionName {
                if (distanceToLocation(destinationGeo: GeofenceLocation(coords: circularArea.center, name: circularArea.identifier), currentLocationGeo: self.currentLocation) < 3.5) {
                    self.labelNearestLocation.text = location.identifier
                    self.textToSpeechManager.toSpeech(location.identifier)
                    self.lastCheckedRegionName = circularArea.identifier
                }
            }
        }
    }
    
    /* User entered CLRegion Area */
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered a region.")
        DispatchQueue.main.async {
            self.textToSpeechManager.toSpeech("You are in \(region.identifier)")
            self.labelNearestLocation.text = region.identifier
        }
    }
    
    /* User exited CLRegion Area */
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited a region.")
        DispatchQueue.main.async {
            self.textToSpeechManager.toSpeech("You have left \(region.identifier)")
            self.labelNearestLocation.text = "Calculating nearest point of interest ..."
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        // didStartMonitoring
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
    
    func addRadiusCircle(location: CLLocation, radius: Double) { // With CLLocation
        self.viewMap.delegate = self
        let circle = MKCircle(center: location.coordinate, radius: radius as CLLocationDistance)
        self.viewMap.addOverlay(circle)
    }
    
    func addRadiusCircleGeo(location: GeofenceLocation, radius: Double) { // With GeofenceLocation
        self.viewMap.delegate = self
        let circle = MKCircle(center: location.getCoordinates(), radius: radius as CLLocationDistance)
        self.viewMap.addOverlay(circle)
    }
    /* ----- END OF OVERLAYING METHODS ----- */
    
    /* Checking region as alternative to didEnter */
    
    // TODO ?
    
    override func viewDidLoad() {
        
        self.clientCallManager.getCoordinatesFromAPI(completion: {
            (data) in
            switch data.isEmpty {
            case true:
                print("The data package seems to be empty.")
            case false:
                /* Converting the JSON response to the required format through SwiftyJSON*/
                let jsonString = String(data: data, encoding: .utf8)
                let jsonData = jsonString!.data(using: .utf8)
                if let json = try? JSON(data: jsonData!)
                {
                    var longs : [String] = []
                    var lats : [String] = []
                    var names : [String] = []
                    
                    for (key, subJson) : (String, JSON) in json {
                        longs.append(String(describing: subJson["longitude"]))
                        lats.append(String(describing: subJson["latitude"]))
                        names.append(String(describing: subJson["name"]))
                    }
                    
                    /* Current number of monitored locations (from API) */
                    DispatchQueue.main.async {
                        self.labelMonitoredRegions.text = String(describing: longs.count)
                    }
                    
                    if (longs.count == 0) {
                        print("No items fetched from API.")
                    }
                    else {
                        for i in 0...longs.count-1 {
                            
                            if (Double(lats[i]) == nil || Double(longs[i]) == nil || names[i].isEmpty) {
                                break
                            }
                            
                            let geofenceObj = GeofenceLocation(coords: CLLocationCoordinate2D(latitude: Double(lats[i])!, longitude: Double(longs[i])!), name: names[i])
                            print("Monitored from API : \(geofenceObj.getCoordinates().latitude) \n")
                            self.geofenceManager.startMonitoring(location: geofenceObj, locationManager: self.locationManager)
                            self.addRadiusCircleGeo(location: geofenceObj, radius: 6)
                        }
                    }
                }
            }
        })
        
        super.viewDidLoad()
        self.textToSpeechManager.toSpeech("Welcome!")
        
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
            locationManager.startUpdatingLocation()
        }
        
        // Zoom to user location
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
            viewMap.setRegion(viewRegion, animated: false)
        }
        
        /*
         for location in self.locationManager.monitoredRegions {
         print("--------- \(location) ---------")
         let circularArea = location as! CLCircularRegion
         if circularArea.contains(self.currentLocation.getCoordinates()) {
         if (distanceToLocation(destinationGeo: GeofenceLocation(coords: circularArea.center, name: circularArea.identifier), currentLocationGeo: self.currentLocation) < 10) {
         DispatchQueue.main.async {
         self.labelNearestLocation.text = location.identifier
         self.textToSpeechManager.toSpeech(location.identifier)
         }
         }
         }
         }
         */
    }
    
}
