//
//  client.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 28/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import Foundation

public class Client {
    
    private let url : URL = URL(string: "https://us-central1-whereami-275517.cloudfunctions.net/app/locations")!
    
    public func getCoordinatesFromAPI(completion: @escaping (_ data: Data) -> Void) {
        let task = URLSession.shared.dataTask(with: self.url) {
            (data, response, error) in
            
            print("Starting request ...")
            
            if let error = error {
                print("error = \(error)")
            }
            
            if let data = data {
                print("data = \(data)")
                completion(data)
            }
        }
        task.resume()
    }
    
}
