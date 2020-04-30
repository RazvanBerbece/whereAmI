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

/* Calculates the distance between two GeofenceLocations and returns a Double */
public func distanceToLocation(destinationGeo: GeofenceLocation, currentLocationGeo: GeofenceLocation) -> Double {
    let destination = CLLocation(latitude: destinationGeo.getCoordinates().latitude, longitude: destinationGeo.getCoordinates().longitude)
    let current = CLLocation(latitude: currentLocationGeo.getCoordinates().latitude, longitude: currentLocationGeo.getCoordinates().longitude)
    return destination.distance(from: current)
}

public class LocationList { /** Will have stack behaviour */
    
    private var locationsQueue : [String]
    
    init() {
        self.locationsQueue = []
    }
    
    public func append(location: String) {
        self.locationsQueue.append(location)
    }
    
    public func delete() {
        if self.locationsQueue.indices.contains(0) {
            self.locationsQueue.remove(at: 0)
        }
    }
    
    public func isEmpty() -> Bool {
        return self.locationsQueue.isEmpty
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
    
    init(coords: CLLocationCoordinate2D, name: String, radius: Double) {
        self.coordinates = coords
        self.name = name
        self.radius = radius // Adjustable ?
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
        let region = CLCircularRegion(center: location.getCoordinates(), radius: location.getRadius(), identifier: location.getName())
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    public func startMonitoring(location: GeofenceLocation, locationManager: CLLocationManager) {
        let fenceRegion = addRegion(with: location)
        locationManager.startMonitoring(for: fenceRegion)
    }
    
    public func isDuplicateCheck(locationManager: CLLocationManager, locationToCheck: GeofenceLocation) -> Bool {
        
        for location in locationManager.monitoredRegions {
            /* If the absolute differences of the coords are minimum, then there is a duplicate */
            let latDiff = fabs((location as! CLCircularRegion).center.latitude - locationToCheck.getCoordinates().latitude)
            let longDiff = fabs((location as! CLCircularRegion).center.longitude - locationToCheck.getCoordinates().longitude)
            
            if latDiff == 0 && longDiff == 0 {
                return true
            }
        }
        
        return false
    }
    
    public func getClosestLocation(locarray: [GeofenceLocation], currentLocation: GeofenceLocation, completion: @escaping ((GeofenceLocation) -> Void)) {
        
        var minDistance : Double = 9999999.9
        var closestRegion = GeofenceLocation()
        
        for location in locarray {
            if (distanceToLocation(destinationGeo: location, currentLocationGeo: currentLocation) < minDistance) {
                minDistance = distanceToLocation(destinationGeo: location, currentLocationGeo: currentLocation)
                closestRegion = GeofenceLocation(coords: location.getCoordinates(), name: location.getName(), radius: location.getRadius())
            }
        }
        completion(closestRegion)
    }
    
}
