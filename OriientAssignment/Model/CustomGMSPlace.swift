//
//  GooglePlace.swift
//  OriientApp
//
//  Created by Rafea Shakkour on 02/04/2021.
//  Copyright © 2021 Rafea Shakkour. All rights reserved.
//

import UIKit
import CoreLocation


struct CustomGMSResponse: Codable {
    let results: [CustomGMSPlace]
    let status: String
}

struct CustomGMSGeometry: Codable {
    let location: CustomGMSCoordinate
}

struct CustomGMSCoordinate: Codable {
    let lat: CLLocationDegrees
    let lng: CLLocationDegrees
}

struct CustomGMSPlace: Codable {
    let name: String
    let vicinity: String
    let geometry: CustomGMSGeometry
    
    enum CodingKeys: String, CodingKey {
        case name
        case vicinity
        case geometry
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: geometry.location.lat, longitude: geometry.location.lng)
    }
}

extension CLLocationCoordinate2D: CustomStringConvertible {
  public var description: String {
    let lat = String(format: "%.6f", latitude)
    let lng = String(format: "%.6f", longitude)
    return "\(lat),\(lng)"
  }
}
