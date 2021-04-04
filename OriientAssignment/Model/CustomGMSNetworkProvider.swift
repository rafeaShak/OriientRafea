//
//  GoogleDataProvider.swift
//  OriientApp
//
//  Created by Rafea Shakkour on 02/04/2021.
//  Copyright © 2021 Rafea Shakkour. All rights reserved.
//

import UIKit
import CoreLocation


class CustomGMSNetworkProvider {
    
    func fetch(
        placesNear coordinate: CLLocationCoordinate2D,
        completion: @escaping ([CustomGMSPlace]) -> Void
    ) -> Void {
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinate)&rankby=distance&key=\(googleApiKey)"
        
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in

            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if let placesResponse = try? decoder.decode(CustomGMSResponse.self, from: data)  {
                DispatchQueue.main.async {
                    completion(placesResponse.results)
                }
            } else {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
        task.resume()
    }
    
}
