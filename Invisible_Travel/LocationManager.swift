//
//  LocationManager.swift
//  Invisible_Travel
//
//  Created by kc on 13/12/2024.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isTracking = true
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.033968, longitude: 121.564468),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @Published var location: CLLocation? // 新增位置属性
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if let location = locations.last {
                DispatchQueue.main.async {
                    self.location = location // 更新位置
                    self.region.center = location.coordinate
                }
            }
        }
    }
    



