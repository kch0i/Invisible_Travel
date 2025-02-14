//
//  DeviceConnectionView.swift
//  Invisible_Travel
//
//  Created by kc on 14/2/2025.
//

import Foundation
import SwiftUI


struct DeviceConnectionView_Previews: View {
    @StateObject private var wsManager = WSManager.shared
    @State private var serverAddress = "ws://192.168.1.100:81"
    @State private var showAlert = false
    
    var body: some View{
        VStack(spacing: 20){
            // Connection status
            HStack{
                Circle()
                    .fill(wsManager.isConnected ? Color.green : Color.red)
                Text(wsManager.isConnected ? "Connected" : "Disconnected")
            }
            
            // Server address input
            TextField("WebSocket Server", text: $serverAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
            
            // Control button
            HStack(spacing: 15) {
                Button(action: toggleConnection) {
                    Text(wsManager.isConnected ? "Disconnect" : "Connect")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(borderedProminent)
                
                Button("Request Status") {
                    let command = DeviceCommand(action: .requestStatus)
                    wsManager.sendCommand(command)
                }
                .buttonStyle(.bordered)
                .disabled(!wsManager.isConnected)
            }
            .padding()
            
            // Error msg
            if let error = wsManager.lastError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle(Text("Device Connection"))
        .alert("Connection Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(wsManager.lastError ?? "Unknown error")
        }
        .onChange(of: wsManager.lastError) { _ in
            showAlert = wsManager.lastError != nil
        }
    }
    
    private func toggleConnection() {
        if wsManager.isConnected {
            wsManager.disconnect()
        } else {
            wsManager.connnet(to: serverAddress, delegate: self)
        }
    }
}


// M: WebSocket Event processing

struct DeviceConnectionView: WSManagerDelegate {
    func didReceiveDeviceStatus(_ status: DeviceStatus) {
        print("Received status:", status)
        // update UI or processing data
    }
    
    func didReceiveVideoFrame(_ image: UIImage) {
        print("Received video frame:", image.size)
        // processing video (it can send to others)
    }
}
