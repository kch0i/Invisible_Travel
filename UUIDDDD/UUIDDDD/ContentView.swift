//
//  ContentView.swift
//  UUIDDDD
//
//  Created by Ip Argus on 20/2/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some View {
        NavigationView {
            VStack {
                Text("🔍 掃描附近的藍牙裝置")
                    .font(.title)
                    .padding()
                
                Text("狀態: \(bluetoothManager.connectionStatus)")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                
                // 🔍 搜尋欄
                TextField("輸入裝置名稱...", text: $bluetoothManager.filterText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                List(bluetoothManager.filteredDevices, id: \.0) { uuid, device in
                    VStack(alignment: .leading) {
                        Text("📡 名稱: \(device.name)")
                            .font(.headline)
                        Text("🆔 UUID: \(uuid)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("📶 RSSI: \(device.rssi) dBm")
                            .font(.subheadline)
                            .foregroundColor(device.rssi >= -60 ? .green : .orange)
                        
                        // 顯示 CBUUID
                        if !device.services.isEmpty {
                            Text("🔗 服務 UUIDs:")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            ForEach(device.services, id: \.self) { service in
                                Text("• \(service.uuidString)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Text("⚠️ 無可用服務 UUID")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .listStyle(PlainListStyle())

                Button(action: {
                    bluetoothManager.startScanning()
                }) {
                    Text("🔄 重新掃描")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("藍牙掃描器")
        }
    }
}
