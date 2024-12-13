//
//  ContentView.swift
//  Invisible_Travel
//
//  Created by kc on 10/12/2024.
//

import SwiftUI
import MapKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {

                Section {
                    NavigationLink(destination: LanguageSettingsView()) {
                        SettingRow(icon: "globe", title: "Language / 語言", detail: "English")
                                        }
                    NavigationLink(destination: TravelGuideView()) {
                        SettingRow(icon: "location.fill", title: "Travel Guide")
                                        }
                    NavigationLink(destination: DeviceInfoView()) {
                        SettingRow(icon: "battery.50", title: "Device Information")
                                        }
                    NavigationLink(destination: DeviceConnectionView()) {
                        SettingRow(icon: "wifi", title: "Device Connection")
                                        }
                    NavigationLink(destination: HeadphoneConnectionView()) {
                        SettingRow(icon: "headphones", title: "Headphone Connection")
                                        }
                    NavigationLink(destination: WeatherInfoView()) {
                        SettingRow(icon: "sun.max", title: "Weather Information")
                                        }
                    NavigationLink(destination: ColourFilterView()) {
                        SettingRow(icon: "textformat.size", title: "Colour Filter")
                                        }
                }
            
            }
            .navigationTitle("Invisible Travel")

            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct SettingRow: View {
    var icon: String
    var title: String
    var detail: String? = nil
    var isToggle: Bool = false
    
    var body: some View {
        HStack {
            
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            
            
            Text(title)
                .font(.title2)
                .foregroundColor(.primary)
            
            Spacer()
            
            
            if let detail = detail {
                Text(detail)
                    .foregroundColor(.gray)
                    .font(.title3)
            } else if isToggle {
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

struct LanguageSettingsView: View {
    var body: some View {
        
       
        
        
        Text("Language Settings")
            .font(.largeTitle)
            .navigationTitle("Language Settings")
    }
}
struct TravelGuideView: View {
        @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.033968, longitude: 121.564468),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
    var body: some View {
        Text("Travel Guide Details")
            .font(.largeTitle)
            .navigationTitle("Travel Guide")
        }
    }

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
    #Preview {
        ContentView()
    }

