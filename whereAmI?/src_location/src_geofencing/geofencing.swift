//
//  geofencing.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 26/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public class LocationList { /** Will have stack behaviour */
    
    private var locations : [String]
    
    init() {
        self.locations = []
    }
    
    public func append(location: String) {
        self.locations.append(location)
    }
    
    public func delete() {
        if self.locations.indices.contains(0) {
            self.locations.remove(at: 0)
        }
    }
    
    public func isEmpty() -> Bool {
        return self.locations.isEmpty
    }
    
}

public class GeofenceLocation { /** Class which is going to be used for all geofencing functions */
    
    private var coordinates : CLLocationCoordinate2D
    private var name : String
    private var radius : Double
    
    init() {
        self.coordinates = CLLocation(latitude: -1, longitude: -1).coordinate
        self.name = "uninitialised"
        self.radius = 0
    }
    
    init(coords: CLLocationCoordinate2D, name: String) {
        self.coordinates = coords
        self.name = name
        self.radius = 10 // Adjustable ?
    }
    
    public func getCoordinates() -> CLLocationCoordinate2D {
        return self.coordinates
    }
    
    public func getName() -> String {
        return self.name
    }
    
    public func getRadius() -> Double {
        return self.radius
    }
    
    public func setCoords(coords: CLLocationCoordinate2D) {
        self.coordinates = coords
    }
    
    public func setName(name: String) {
        self.name = name
    }
    
    public func setRadius(radius: Double) {
        self.radius = radius
    }
}

public class GeofencingManager { /** This manages the addition or processing of the geofencing locations to the MapKit */
    
    public func addRegion(with location: GeofenceLocation) -> CLCircularRegion {
        print("Creating region ...")
        let region = CLCircularRegion(center: location.getCoordinates(), radius: location.getRadius(), identifier: location.getName())
        return region
    }
    
    public func startMonitoring(location: GeofenceLocation, locationManager: CLLocationManager) {
        let fenceRegion = addRegion(with: location)
        print("Monitoring region ...")
        locationManager.startMonitoring(for: fenceRegion)
    }
    
    public func distanceToLocation(destinationGeo: GeofenceLocation, currentLocationGeo: GeofenceLocation) -> Double {
        let destination = CLLocation(latitude: destinationGeo.getCoordinates().latitude, longitude: destinationGeo.getCoordinates().longitude)
        let current = CLLocation(latitude: currentLocationGeo.getCoordinates().latitude, longitude: currentLocationGeo.getCoordinates().longitude)
        return destination.distance(from: current)
    }
    
}
