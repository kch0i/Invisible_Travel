//
//  DeviceConnectionView.swift
//  Invisible_Travel
//
//  Created by kc on 14/2/2025.
//

import Foundation
import SwiftUI


struct DeviceConnectionView: View {
    @StateObject private var wsManager = WSManager.shared
    @State private var serverAddress = "ws://192.168.1.100:81"
    @State private var showAlert = false
    @StateObject private var delegateHandler = WSDelegateHandler()
    
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
                .buttonStyle(.borderedProminent)
                
                Button("Request Status") {
                    let command = DeviceInfoCommand(action: .requestStatus)
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
            delegateHandler().onStatusMessage = { status in
                print("Received status: \(status)")
            }
            delegateHandler().onVideoFrame = { image in
                print("Received video frame: ", image.size)
            }
            WSManager.connect(to: serverAddress, delegate: delegateHandler)
            }
        }
    }



// M: WebSocket Event processing
private class WSDelegateHandler: NSObject, WSManagerDelegate {
    var onStatusMessage: ((StatusMessage) -> Void)?
    var onVideoFrame: ((UIImage) -> Void)?
    
    func didReceiveStatusMessage(_ status: StatusMessage) {
        onStatusMessage?(status)
    }
    
    func didReceiveVideoFrame(_ image: UIImage) {
        onVideoFrame?(image)
    }
}




#Preview {
    DeviceConnectionView()
}



