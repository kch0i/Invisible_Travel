//
//  TravelGuideView.swift
//  Invisible_Travel
//
//  Created by kc on 5/2/2025.
//

import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKMapItem: @retroactive Identifiable {
    public var id: String {
        "\(self.placemark.coordinate.latitude)-\(self.placemark.coordinate.longitude)"
    }
}

struct TravelGuideView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var directions: [String] = []
    @State private var showRoute = false
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $locationManager.region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow),
                annotationItems: destinationCoordinate != nil ? [AnnotationItem(coordinate: destinationCoordinate!)] : []
            ) { item in
                MapMarker(coordinate: item.coordinate, tint: .red)
            }
            
            VStack {
                SearchBarView { coordinate in
                    self.destinationCoordinate = coordinate
                }
                .padding()
                
                Spacer()
                
                if showRoute {
                    NavigationInstructionsView(directions: $directions)
                }
            }
        }
        .onChange(of: destinationCoordinate) {
            calculateRoute()
        }
    }
    
    private func calculateRoute() {
        guard let userLocation = locationManager.location?.coordinate,
              let destination = destinationCoordinate else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Route calculation error: \(error.localizedDescription)")
                return
            }
            
            guard let route = response?.routes.first else { return }
            
            DispatchQueue.main.async {
                self.directions = route.steps.compactMap {
                    $0.instructions?.isEmpty == false ? $0.instructions : nil
                }
                self.showRoute = true
            }
        }
    }
}

struct AnnotationItem: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct SearchBarView: View {
    @EnvironmentObject var locationManager: LocationManager
    var onLocationSelected: (CLLocationCoordinate2D) -> Void
    
    @State private var searchText = ""
    @State private var searchResults = [MKMapItem]()
    
    var body: some View {
        VStack {
            TextField("輸入目的地地址", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: searchText) {
                    searchLocations()
                }
            
            List(searchResults) { item in
                VStack(alignment: .leading) {
                    Text(item.name ?? "")
                    Text(item.placemark.title ?? "")
                        .font(.caption)
                }
                .onTapGesture {
                    onLocationSelected(item.placemark.coordinate)
                    searchResults = []
                }
            }
            .frame(maxHeight: 200)
        }
    }
    
    private func searchLocations() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = locationManager.region
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                searchResults = response?.mapItems ?? []
            }
        }
    }
}

struct NavigationInstructionsView: View {
    @Binding var directions: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("導航指示")
                .font(.headline)
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(directions, id: \.self) { instruction in
                        HStack {
                            Image(systemName: "arrow.turn.up.right")
                                .accessibilityHidden(true)
                            Text(instruction)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .accessibilityElement(children: .combine)
                        .accessibilityHint("導航步驟")
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("導航指示清單，共\(directions.count)個步驟")
    }
}
