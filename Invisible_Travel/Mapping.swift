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
    @StateObject private var routeManager = RouteManager()
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(searchText: $searchText, results: $searchResults)
                .padding()
                .background(.bar)
            
            Map(position: $position) {
                UserAnnotation()
                searchResultsMarkers
                routeOverlays
            }
            .mapStyle(.standard)
            .frame(maxHeight: .infinity)
            .onChange(of: routeManager.route) { oldValue, newValue in
                handleRouteChange(newValue: newValue)
            }
        }
    }
    
    // MARK: - 視圖組件分解
    @ViewBuilder
    private var searchResultsMarkers: some View {
        ForEach(searchResults, id: \.self) { item in
            Annotation(item.name ?? "", coordinate: item.placemark.coordinate) {
                Image(systemName: "mappin")
                    .foregroundStyle(.blue)
                    .onTapGesture { handleLocationSelection(item: item) }
            }
        }
    }
    
    @ViewBuilder
    private var routeOverlays: some View {
        if let route = routeManager.route {
            MapPolyline(route.polyline)
                .stroke(.blue, lineWidth: 4)
            
            Annotation("起點", coordinate: route.polyline.coordinate) {
                Image(systemName: "circle.circle.fill").foregroundStyle(.green)
            }
            
            if let lastCoordinate = route.polyline.coordinates.last {
                Annotation("終點", coordinate: lastCoordinate) {
                    Image(systemName: "flag.checkered").foregroundStyle(.red)
                }
            }
        }
    }
    
    // MARK: - 邏輯處理
    private func handleLocationSelection(item: MKMapItem) {
        guard let userLocation = getCurrentUserLocation() else { return }
        routeManager.calculateRoute(from: userLocation, to: item.placemark.coordinate)
    }
    
    private func handleRouteChange(newValue: MKRoute?) {
        guard let route = newValue else { return }
        withAnimation {
            position = .rect(route.polyline.boundingMapRect)
        }
    }
    
    private func getCurrentUserLocation() -> CLLocationCoordinate2D? {
        return CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5172)
    }
}
    
    // 處理地點選擇 (新增方法)
    private func handleLocationSelection(item: MKMapItem) {
        guard let userLocation = getCurrentUserLocation() else {
            print("無法取得當前位置")
            return
        }
        
        let destination = item.placemark.coordinate
        routeManager.calculateRoute(
            from: userLocation,
            to: destination
        )
    }
    
    // 獲取假設的用戶位置 (需替換為真實定位)
    private func getCurrentUserLocation() -> CLLocationCoordinate2D? {
        // 暫時使用台北車站座標作為示例
        return CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5172)
    }
}


// searchbar

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var results: [MKMapItem]
    
    // 新增搜索防抖動
    @State private var searchTask: DispatchWorkItem?
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: routeManager.route) { oldValue, newValue in
                    guard let route = newValue else { return }
                    withAnimation {
                        position = .rect(route.polyline.boundingMapRect)
                    }
                }
            
            List(results, id: \.self) { item in
                VStack(alignment: .leading) {
                    Text(item.name ?? "unknown location")
                    Text(item.placemark.title ?? "")
                        .font(.caption)
                }
                // 點擊列表項目觸發路線計算
                .onTapGesture {
                    searchText = ""  // 清空搜索欄
                }
            }
        }
    }
    
    private func performDelayedSearch() {
        searchTask?.cancel()
        let task = DispatchWorkItem {
            self.performSearch()
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }
    
    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5172),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        request.resultTypes = .pointOfInterest
        
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                self.results = response?.mapItems ?? []
            }
        }
    }
}

// route calculate

class RouteManager: ObservableObject {
    @Published var route: MKRoute?
    
    func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .walking  // 改為步行模式
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard error == nil else {
                print("路線計算錯誤: \(error!.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.route = response?.routes.first
            }
        }
    }
}
