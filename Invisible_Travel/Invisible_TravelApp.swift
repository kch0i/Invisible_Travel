//
//  Invisible_TravelApp.swift
//  Invisible_Travel
//
//  Created by kc on 10/12/2024.
//

import SwiftUI

// Invisible_TravelApp.swift
@main
struct Invisible_TravelApp: App {
    @StateObject var locationManager = LocationManager() // 新增状态对象
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager) // 注入环境对象
        }
    }
}

