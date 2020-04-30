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
    
    /* Sends the current location to the API through a POST req */
    @IBAction func pushCurrentLocation(_ sender: UIButton) { print("-------> STARTING POST REQUEST")
        
        guard let currentLocationCoords : CLLocationCoordinate2D = self.currentLocation.getCoordinates() else { return }
        
        var locationToBePushed = GeofenceLocation()
        
        var name : String = ""
        var radius : Double = -1.0
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Add Location to Database", message: "Please Input the Required Data", preferredStyle: .alert)
        
        //2. Add the text fields. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Name of location"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Radius (in m)"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
            let textField1 = alert?.textFields![0]
            let textField2 = alert?.textFields![1]
            name = textField1!.text!
            radius = Double(textField2!.text!)!
            locationToBePushed = GeofenceLocation(coords: currentLocationCoords, name: name, radius: radius)
            
            print("----------> GOT DATA : \(locationToBePushed.getName()) &&&& \(locationToBePushed.getRadius())")
            
            self.clientCallManager.postCoordinatesToAPI(location: locationToBePushed, completion: {
                (result) in
                switch result {
                case true:
                    print("Added location to database!")
                case false:
                    print("Post request failed.")
                }
            })
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }
    
    /* Current location / testing objects as GeofenceLocation */
    private var currentLocation = GeofenceLocation()
    private var lastCheckedRegionName : String = ""
    
    /* Other Variables */
    let newGeofenceLocation = GeofenceLocation(coords: CLLocation(latitude: 51.44737, longitude: -0.23890).coordinate, name: "Home", radius: 3)
    let newGeofenceLocation2 = GeofenceLocation(coords: CLLocation(latitude: 51.447375147473, longitude: -0.238789905617).coordinate, name: "Garden", radius: 5)
    
    /* Called at runtime, manages evrything related to the current location */
    /** Listening for locations and printing them as the current one changes */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        /* Updating labels with current coordinates (12 decimal places) */
        self.labelLocationLong.text = String(format: "%.15f", locValue.longitude)
        self.labelLocationLat.text = String(format: "%.15f", locValue.latitude)
        
        /* Setting class variables for the Analysis class */
        self.locationAnalysisClass.setLat(lat: locValue.latitude)
        self.locationAnalysisClass.setLong(long: locValue.longitude)
        
        /* Reverse geocoding & Change label to current City */
        self.locationAnalysisClass.reverseGeolocation(completion: {
            (result) -> Void in
            if !result.isEmpty {
                /* Setting the current location GeofenceLocation */
                self.currentLocation.setCoords(coords: locValue)
                self.currentLocation.setName(name: result)
                self.currentLocation.setRadius(radius: 2)
                
                /* Setting the current city label */
                DispatchQueue.main.async {
                    self.labelCurrentCity.text = "\(result as String)"
                }
                
                if !self.appStarted { // If the app just started, we check if the user is in a checked region
                    
                    var closeToLocations : [GeofenceLocation] = []
                    
                    var minDistance : Double = 9999999.9
                    var closestRegion = GeofenceLocation()
                    
                    self.textToSpeechManager.toSpeech("You are in \(result)")
                    
                    /* Going through all the monitored locations available at the moment and checking if they contain the current location */
                    for location in self.locationManager.monitoredRegions {
                        let circularArea = location as! CLCircularRegion
                        if circularArea.contains(self.currentLocation.getCoordinates()) && (circularArea.identifier != self.lastCheckedRegionName) {
                            closeToLocations.append(GeofenceLocation(coords: circularArea.center, name: circularArea.identifier, radius: Double(circularArea.radius)))
                            break;
                        }
                    }
                    
                    /*
                     Getting the location which contains the user with the minimum distance,
                     to avoid duplicate TTS statements
                     */
                    
                    for location in closeToLocations {
                        if (distanceToLocation(destinationGeo: location, currentLocationGeo: self.currentLocation) < minDistance) {
                            minDistance = distanceToLocation(destinationGeo: location, currentLocationGeo: self.currentLocation)
                            closestRegion = GeofenceLocation(coords: location.getCoordinates(), name: location.getName(), radius: location.getRadius())
                        }
                    }
                    
                    /* Setting variables using the resulted location */
                    if (closestRegion.getName() != "uninitialised") {
                        self.labelNearestLocation.text = closestRegion.getName()
                        self.lastCheckedRegionName = closestRegion.getName()
                        self.textToSpeechManager.toSpeech(self.lastCheckedRegionName)
                        self.currentLocation.setName(name: closestRegion.getName())
                    }
                    
                    closeToLocations = []
                    // App went past the first check of location
                    self.appStarted = true
                }
                else {
                    
                    /*
                     Constantly checking if user is in one of the regions
                     Implemented as backup in case didEnterRegion doesn't work as intended,
                     Which seems to be the case
                     */
                    var closeToLocations : [GeofenceLocation] = []
                    
                    for location in self.locationManager.monitoredRegions {
                        let circularArea = location as! CLCircularRegion
                        if circularArea.contains(self.currentLocation.getCoordinates()) && (circularArea.identifier != self.lastCheckedRegionName) {
                            closeToLocations.append(GeofenceLocation(coords: circularArea.center, name: circularArea.identifier, radius: Double(circularArea.radius)))
                        }
                    }
                    
                    self.geofenceManager.getClosestLocation(locarray: closeToLocations, currentLocation: self.currentLocation, completion: {
                        (closestLocation) in
                        /* Setting variables using the resulted location */
                        if (closestLocation.getName() != "uninitialised") {
                            self.labelNearestLocation.text = closestLocation.getName()
                            self.lastCheckedRegionName = closestLocation.getName()
                            self.textToSpeechManager.toSpeech(self.lastCheckedRegionName)
                            self.currentLocation.setName(name: closestLocation.getName())
                        }
                    })
                    
                    closeToLocations = []
                    
                }
            }
        })
        
    }
    
    /* User entered CLRegion Area */
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered a region.")
        self.textToSpeechManager.toSpeech("You are in \(region.identifier)")
        self.labelNearestLocation.text = region.identifier
    }
    
    /* User exited CLRegion Area */
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited a region.")
        self.textToSpeechManager.toSpeech("You have left \(region.identifier)")
        self.labelNearestLocation.text = "Calculating nearest point of interest ..."
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
    
    /* Adds a circle shape on a location but using a GeofenceLocation object as main param */
    func addRadiusCircleGeo(location: GeofenceLocation, radius: Double) { // With GeofenceLocation
        self.viewMap.delegate = self
        let circle = MKCircle(center: location.getCoordinates(), radius: radius as CLLocationDistance)
        self.viewMap.addOverlay(circle)
    }
    
    func addOverlayDesc(mapView: MKMapView, text: String, atCoordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.title = text
        annotation.coordinate = atCoordinates
        DispatchQueue.main.async {
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        
        return annotationView
    }
    /* ----- END OF OVERLAYING METHODS ----- */
    
    override func viewDidLoad() {
        
        /* Calling API for database locations and adding them on the MKMapView */
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
                    
                    /* Adding default app locations to be monitored for geofencing */
                    self.geofenceManager.startMonitoring(location: self.newGeofenceLocation, locationManager: self.locationManager)
                    self.geofenceManager.startMonitoring(location: self.newGeofenceLocation2, locationManager: self.locationManager)
                    self.addRadiusCircle(location: CLLocation(latitude: self.newGeofenceLocation.getCoordinates().latitude, longitude: self.newGeofenceLocation.getCoordinates().longitude), radius: self.newGeofenceLocation.getRadius())
                    self.addRadiusCircle(location: CLLocation(latitude: self.newGeofenceLocation2.getCoordinates().latitude, longitude: self.newGeofenceLocation2.getCoordinates().longitude), radius: self.newGeofenceLocation2.getRadius())
                    self.addOverlayDesc(mapView: self.viewMap, text: self.newGeofenceLocation.getName(), atCoordinates: self.newGeofenceLocation.getCoordinates())
                    self.addOverlayDesc(mapView: self.viewMap, text: self.newGeofenceLocation2.getName(), atCoordinates: self.newGeofenceLocation2.getCoordinates())
                    
                    var longs : [String] = []
                    var lats : [String] = []
                    var names : [String] = []
                    var radiuss : [String] = []
                    
                    /* Iterating through the (randomized key from Firebase) - (user input) pairs */
                    /* The subjson holds each of the Location data needed */
                    for (_, subJson) : (String, JSON) in json {
                        longs.append(String(describing: subJson["longitude"]))
                        lats.append(String(describing: subJson["latitude"]))
                        names.append(String(describing: subJson["name"]))
                        radiuss.append(String(describing: subJson["radius"]))
                    }
                    
                    /* Current number of monitored locations (from API) */
                    self.labelMonitoredRegions.text = String(describing: longs.count + 2)
                    
                    if (longs.count == 0) {
                        print("No items fetched from API.")
                    }
                    else {
                        for i in 0...longs.count-1 { // Adding regions to the monitored set one by one
                            
                            if (Double(lats[i]) == nil || Double(longs[i]) == nil || names[i].isEmpty || Double(radiuss[i]) == nil) { // One of the data can't be parsed
                                break
                            }
                            
                            let geofenceObj = GeofenceLocation(coords: CLLocationCoordinate2D(latitude: Double(lats[i])!, longitude: Double(longs[i])!), name: names[i], radius: Double(radiuss[i])!)
                            
                            print("Monitored from API : \(geofenceObj.getCoordinates().latitude) \n")
                            
                            /* Monitoring and adding overlay on map */
                            self.geofenceManager.startMonitoring(location: geofenceObj, locationManager: self.locationManager)
                            self.addRadiusCircleGeo(location: geofenceObj, radius: geofenceObj.getRadius())
                            self.addOverlayDesc(mapView: self.viewMap, text: geofenceObj.getName(), atCoordinates: geofenceObj.getCoordinates())
                        }
                    }
                }
            }
        })
        
        super.viewDidLoad()
        self.textToSpeechManager.toSpeech("Welcome!")
        
        /* FontAwesome_swift in action ! */
        self.headerIcon.font = UIFont.fontAwesome(ofSize: 25, style: .brands)
        self.headerIcon.text = String.fontAwesomeIcon(name: .apple)
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        // Init CLLocationManager
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        }
        
        // Zoom to user location
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
            viewMap.setRegion(viewRegion, animated: false)
        }
        
    }
    
}
