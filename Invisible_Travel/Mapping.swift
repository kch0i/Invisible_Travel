//
//  Mapping.swift
//  Invisible_Travel
//
//  Created by kc on 8/2/2025.
//

import SwiftUI
import MapKit

// basic UI of mapping

struct Mapping: View {
    @State private var position = MapCameraPosition.automatic
    @State private var searchText = ""
    @State private var searchResults = [MKMapItem]()
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(searchText: $searchText, results: $searchResults)
                .padding()
                .background(.bar)
            
            Map(position: $position) {
                UserAnnotation()
                
                // 顯示所有搜索結果標記
                ForEach(searchResults, id: \.self) { item in
                    Annotation(item.name ?? "", coordinate: item.placemark.coordinate) {
                        Image(systemName: "mappin")
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                print("you have choose：\(item.name ?? "")")
                            }
                    }
                }
            }
            .mapStyle(.standard)
            .frame(maxHeight: .infinity)
        }
    }
}


// searchbar

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var results: [MKMapItem]
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { performSearch() }
            
            List(results, id: \.self) { item in
                VStack(alignment: .leading) {
                    Text(item.name ?? "unknown location")
                    Text(item.placemark.title ?? "")
                        .font(.caption)
                }
            }
        }
    }
    
    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = .pointOfInterest
        
        MKLocalSearch(request: request).start { response, _ in
            results = response?.mapItems ?? []
        }
    }
}

class RouateManager: ObservableObject {
    @Published var route: MKRoute?
    
    func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .automobile
        
        MKDirections(request: request).calculate { [weak self] response, _ in
            self?.route = response?.routes.first
        }
    }
}
