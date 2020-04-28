//
//  client.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 28/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import Foundation

public class Client {
    
    private let url : URL = URL(string: "http://192.168.0.39:3000/locations")!
    
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
