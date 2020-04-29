//
//  client.swift
//  whereAmI?
//
//  Created by Razvan-Antonio Berbece on 28/04/2020.
//  Copyright © 2020 Razvan-Antonio Berbece. All rights reserved.
//

import Foundation
import Alamofire

public class Client {
    
    private let url : URL = URL(string: "https://us-central1-whereami-275517.cloudfunctions.net/app/locations")!
    
    public func getCoordinatesFromAPI(completion: @escaping (_ data: Data) -> Void) {
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
