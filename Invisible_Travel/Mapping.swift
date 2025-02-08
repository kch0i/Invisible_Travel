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
    @State private var visibleRegion: MKCoordinateRegion?
    
    var body: some View {

        
        Map(position: $position) {
            UserAnnotation()
        }
        .mapStyle(.standard)
        .onMapCameraChange { context in
            visibleRegion = context.region
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
                .onSubmit { performSearch(query: searchText, options: []) }
            
            List(results) { item in
                VStack(alignment: .leading) {
                    Text(item.name ?? "unknown location")
                    Text(item.placemark.title ?? "")
                        .font(.caption)
                }
            }
        }
    }
}
