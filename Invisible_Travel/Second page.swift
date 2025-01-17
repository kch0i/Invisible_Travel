//
//  Second page.swift
//  Invisible_Travel
//
//  Created by kc on 13/12/2024.
//

import SwiftUI
import MapKit




struct DeviceInfoView: View {
    var body: some View {
        Text("Device Information")
            .font(.largeTitle)
            .navigationTitle("Device Information")
    }
}

struct DeviceConnectionView: View {
    var body: some View {
        Text("Device Connection Details")
            .font(.largeTitle)
            .navigationTitle("Device Connection")
    }
}

struct HeadphoneConnectionView: View {
    var body: some View {
        Text("Headphone Connection Details")
            .font(.largeTitle)
            .navigationTitle("Headphone Connection")
    }
}

struct WeatherInfoView: View {
    var body: some View {
        Text("Weather Information Details")
            .font(.largeTitle)
            .navigationTitle("Weather Information")
    }
}

struct ColourFilterView: View {
    var body: some View {
        Text("Colour Filter Settings")
            .font(.largeTitle)
            .navigationTitle("Colour Filter")
    }
}
