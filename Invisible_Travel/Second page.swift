//
//  Second page.swift
//  Invisible_Travel
//
//  Created by kc on 13/12/2024.
//

import SwiftUI
import MapKit

/*
struct LanguageSettingsView: View {
    var body: some View {
        @ObservedObject var languageManager = LanguageManager.shared // 語言管理器共享實例
            NavigationView {
                VStack {
                    List {
                        Section(header: Text(languageManager.localizedString(for: "Settings"))) {
                            Text(languageManager.localizedString(for: "Language / 語言"))
                                .font(.title2)
                                .padding()

                            Picker(selection: $languageManager.currentLanguage, label: Text(languageManager.localizedString(for: "Select Language"))) {
                                Text("English").tag("en")
                                Text("中文").tag("zh-Hans")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: languageManager.currentLanguage) { newLanguage in
                                    languageManager.setLanguage(newLanguage)
                                }
                            }
                        }
                    }
                    .navigationTitle(languageManager.localizedString(for: "App Title"))
                    .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                        // 監聽語言切換通知，刷新界面
                        languageManager.objectWillChange.send()
                    }
                }
            }
    }
*/


struct TravelGuideView: View {
    @StateObject private var locationManager = LocationManager()

        var body: some View {
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true)
                .edgesIgnoringSafeArea(.all)
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
