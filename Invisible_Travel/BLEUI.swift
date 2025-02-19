//
//  BLEUI.swift
//  Invisible_Travel
//
//  Created by kc on 19/2/2025.
//

import SwiftUI

struct HeadphoneConnectionView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Circle()
                .frame(width: 200, height: 200)
                .foregroundColor(bluetoothManager.isConnected ? .green : .red)

            
            Toggle("bluetooth connected", isOn: Binding(
                get: { bluetoothManager.isConnected },
                set: { bluetoothManager.toggleConnection($0) }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .font(.title)
            .padding()
            
            
            
           
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

