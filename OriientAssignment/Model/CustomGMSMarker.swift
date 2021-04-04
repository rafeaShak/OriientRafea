//
//  PlaceMarker.swift
//  OriientApp
//
//  Created by Rafea Shakkour on 02/04/2021.
//  Copyright © 2021 Rafea Shakkour. All rights reserved.
//

import UIKit
import GoogleMaps

class CustomGMSMarker: GMSMarker {
    
  let place: CustomGMSPlace
    
  init(place: CustomGMSPlace) {
    
    self.place = place
    super.init()
    
    position = place.coordinate
    appearAnimation = .pop
    opacity = 0.3
  }
}
