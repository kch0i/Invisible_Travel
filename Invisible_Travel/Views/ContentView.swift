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
                    /*
                    NavigationLink(destination: LanguageSettingsView()) {
                        SettingRow(icon: "globe", title: "Language / 語言", detail: "English")
                                        }
                    */

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
                .lineLimit(nil)
                .padding(.leading)
            
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


#Preview {
    ContentView()
    }

