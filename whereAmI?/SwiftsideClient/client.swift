//
//  client.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 28/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import Foundation
import Alamofire

struct PostLocation: Encodable {
    let latitude: String
    let longitude: String
    let name: String
    let radius: String
}

public class Client {
    
    private let url : URL = URL(string: "https://us-central1-whereami-275517.cloudfunctions.net/app/locations")!
    
    public func getCoordinatesFromAPI(completion: @escaping (_ data: Data) -> Void) {
        DispatchQueue.main.async {
            AF.request(self.url, method: .get)
                .responseJSON {
                    (response) in
                    switch response.result {
                    case .success:
                        completion(response.data!)
                    case .failure(let error):
                        print(error)
                    }
            }
        }
    }
    
    public func postCoordinatesToAPI(location: GeofenceLocation, completion: @escaping (Bool) -> Void) {
        let toBePosted = PostLocation(latitude: String(describing: location.getCoordinates().latitude), longitude: String(describing: location.getCoordinates().longitude), name: location.getName(), radius: String(describing: location.getRadius()))
        DispatchQueue.main.async {
            AF.request(self.url, method: .post, parameters: toBePosted, encoder: JSONParameterEncoder.default).response {
                (response) in
                switch response.result {
                case .success:
                    print(response)
                    completion(true)
                case .failure(let error):
                    print(error)
                    completion(false)
                }
            }
        }
    }
    
}
