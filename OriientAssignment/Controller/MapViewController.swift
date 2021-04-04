//
//  ViewController.swift
//  OriientApp
//
//  Created by Rafea Shakkour on 02/04/2021.
//  Copyright © 2021 Rafea Shakkour. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    @IBOutlet private weak var mapView: GMSMapView!
    let locationManager = CLLocationManager()
    let networkProvider = CustomGMSNetworkProvider()
    var nearestPlaces = [CustomGMSMarker]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if CLLocationManager.locationServicesEnabled() {
            locationEnabledSetup()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        locationManager.stopUpdatingLocation()
    }
    
    private func degToRad(_ degree: Double) -> Double {
        degree * Double.pi / 180.0
    }
    
    private func radToDeg(_ radian: Double) -> Double {
        radian *  180.0 / Double.pi
    }
    
    
    private func fetchPlaces(near coordinate: CLLocationCoordinate2D) {
        mapView.clear()
        
        networkProvider.fetch(
            placesNear: coordinate
        ) { [weak self] (places: [CustomGMSPlace]) in
            guard let self = self else {
                return
            }
            // Take the first 5 nearest places
            let places = places.prefix(5)
            self.nearestPlaces = []
            
            places.forEach { place in
                
                let marker = CustomGMSMarker(place: place)
                marker.map = self.mapView
                
                self.nearestPlaces.append(marker)
            }
        }
    }
    
    private func locationEnabledSetup() {
        // Update the location when the user moves at least 300 meters
        locationManager.distanceFilter = 300.0
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        
        locationManager.startUpdatingLocation()
        
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        
        case .authorizedAlways:
            locationEnabledSetup()
            
        case .authorizedWhenInUse:
            locationEnabledSetup()
            
        default:
            return
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        fetchPlaces(near: location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
        
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {

        guard let currentCoordinate = locationManager.location?.coordinate, !nearestPlaces.isEmpty  else {
            return
        }
        
        //  Adjust the magnetic heading to be the lower bound of a range of 45 degrees
        let adjustedHeading = newHeading.magneticHeading - 22.5 >= 0 ? newHeading.magneticHeading - 22.5 : 360.0 + (newHeading.magneticHeading - 22.5)
        
        let currentPoint = coordinateToPoint(for: currentCoordinate)
        
        nearestPlaces.forEach { (placeMarker) in
            // Convert the coordinate to a point
            let placeMarkerPoint = coordinateToPoint(for: placeMarker.place.coordinate)
            // Assume that the axis' origin is the current location, and then subtract it's coordinate from all place marker points
            let adjustedPlaceMarkerPoint = CGPoint(x: placeMarkerPoint.x - currentPoint.x, y: currentPoint.y - placeMarkerPoint.y)
            // Calculate the angle that is created by the line that goes through the origin and the adjusted place marker point, and the positive direction of X axis
            let angleWithPositiveXAxis = calcAngleWithPositiveX(forPoint: adjustedPlaceMarkerPoint)
            // Calculate the angle that is created by the line that goes through the origin and the adjusted place marker point, and the positive direction of Y axis
            let angleWithPositiveYAxisClockWise = calcAngleWithPositiveYClockWise(forPoint: adjustedPlaceMarkerPoint, withAngle: angleWithPositiveXAxis)
            // Check if the angle is inside the range of angles that the user is seeing right now
            if angleWithPositiveYAxisClockWise >= adjustedHeading && angleWithPositiveYAxisClockWise <= adjustedHeading + 45.0  {
                placeMarker.opacity = 1
            // Check if the angle is inside a range of angles that is distributed between the first and the fourth quadrants
            } else if (adjustedHeading + 45.0) > 360.0 && (angleWithPositiveYAxisClockWise >= adjustedHeading || angleWithPositiveYAxisClockWise <= (adjustedHeading + 45.0) - 360.0) {
                placeMarker.opacity = 1
            } else {
                placeMarker.opacity = 0.3
            }
        }
    }
    
    
    func coordinateToPoint(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        let projection = mapView.projection
        return projection.point(for: coordinate)
    }
    
    func calcAngleWithPositiveX(forPoint adjustedPlaceMarkerPoint: CGPoint) -> Double {
        var angleWithPositiveXAxis: Double
        // In case the point is on the Y axis, then there are two options
        if adjustedPlaceMarkerPoint.x == 0 {
            angleWithPositiveXAxis = adjustedPlaceMarkerPoint.y >= 0 ? 0 : 270
        } else {
            // Otherwise, we calculate the slope of the line that goes through the `adjustedPlaceMarkerPoint` and the origin. and then we calculate the angle between the line and the positive direction of X axis
            angleWithPositiveXAxis = radToDeg(Double(atan(adjustedPlaceMarkerPoint.y / adjustedPlaceMarkerPoint.x)))
            angleWithPositiveXAxis = angleWithPositiveXAxis < 0 ? angleWithPositiveXAxis + 180 : angleWithPositiveXAxis
        }
        return angleWithPositiveXAxis
    }
    
    func calcAngleWithPositiveYClockWise(forPoint adjustedPlaceMarkerPoint: CGPoint, withAngle angleWithPositiveXAxis: Double) -> Double {
        var angleWithPositiveYAxisClockWise: Double
        // first quadrant
        if adjustedPlaceMarkerPoint.x >= 0 && adjustedPlaceMarkerPoint.y >= 0 {
            angleWithPositiveYAxisClockWise = 90 - angleWithPositiveXAxis
        // Second quadrant
        } else  if adjustedPlaceMarkerPoint.x <= 0 && adjustedPlaceMarkerPoint.y >= 0 {
            angleWithPositiveYAxisClockWise = 360 - (angleWithPositiveXAxis - 90)
        // Third quadrant
        }else  if adjustedPlaceMarkerPoint.x <= 0 && adjustedPlaceMarkerPoint.y <= 0 {
            angleWithPositiveYAxisClockWise = 270 - angleWithPositiveXAxis
        // Fourth quadrant
        }else {
            angleWithPositiveYAxisClockWise = 180 - (angleWithPositiveXAxis - 90)
        }
        return angleWithPositiveYAxisClockWise
    }
    
}


extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        guard let placeMarker = marker as? CustomGMSMarker else {
            return nil
        }
        guard let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView else {
            return nil
        }
        
        infoView.nameLabel.text = placeMarker.place.name
        infoView.addressLabel.text = placeMarker.place.vicinity
        
        return infoView
    }
}

extension UIView {
    class func viewFromNibName(_ name: String) -> UIView? {
        let views = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
        return views?.first as? UIView
    }
}
