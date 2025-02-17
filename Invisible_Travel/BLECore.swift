//
//  BLECore.swift
//  Invisible_Travel
//
//  Created by kc on 17/2/2025.
//

import Foundation
import CoreBluetooth
import SwiftUI

// MARK: - Device Filter Engine
final class DeviceFilterEngine {
    /// Fuzzy matching rules for audio devices
    private let namePattern = "(?i)audio|headset"
    
    /// Apply name filtering rules
    func applyNameFilter(_ name: String) -> Bool {
        return name.range(of: namePattern, options: .regularExpression) != nil
    }
}

// MARK: - Scan Scheduler
final class ScanScheduler {
    /// Scan interval in seconds
    private let interval: TimeInterval = 30
    private weak var manager: BluetoothManager?
    
    init(manager: BluetoothManager) {
        self.manager = manager
    }
    
    /// Start auto refresh
    func startAutoRefresh() {
        guard let manager = manager else { return }
        
        manager.stopScan()
        manager.startScan()
        scheduleNextRefresh()
    }
    
    /// Schedule next refresh
    private func scheduleNextRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.startAutoRefresh()
        }
    }
}

// MARK: - Haptic Feedback
enum HapticFeedbackType {
    case connectionSuccess
    case timeout
}

final class HapticFeedbackController {
    /// Trigger specific feedback type
    static func trigger(_ type: HapticFeedbackType) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        switch type {
        case .connectionSuccess:
            generator.impactOccurred(intensity: 1.0)
        case .timeout:
            generator.impactOccurred(intensity: 0.5)
        }
    }
}

// MARK: - Bluetooth Manager Extension
extension BluetoothManager {
    /// Enhanced device discovery handling
    func enhancedProcessDiscoveredPeripheral(
        _ peripheral: CBPeripheral,
        rssi: NSNumber,
        filterEngine: DeviceFilterEngine
    ) {
        guard peripheral.name != nil else { return }
        
        let isValidName = filterEngine.applyNameFilter(peripheral.name!)
        let isValidRSSI = rssi.intValue >= -100
        
        if isValidName && isValidRSSI {
            processDiscoveredPeripheral(peripheral, rssi: rssi)
        }
    }
    
    /// Immediate device connection
    func immediateConnect(_ device: BluetoothDevice) {
        guard let peripheral = device.peripheral else { return }
        
        // Reset connection state
        connectionTimeoutTimers[device.id]?.invalidate()
        device.state = .connecting
        device.lastConnectionAttempt = Date()
        
        // Initiate system connection
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
        
        startConnectionTimer(for: device)
    }
    
    /// Force disconnect device
    func forceDisconnect(_ device: BluetoothDevice) {
        guard let peripheral = device.peripheral else { return }
        
        // Cleanup related resources
        connectionTimeoutTimers[device.id]?.invalidate()
        peripheral.delegate = nil
        centralManager.cancelPeripheralConnection(peripheral)
        
        // Update state immediately
        if let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) {
            discoveredDevices[index].state = .disconnected
        }
    }
}

// MARK: - Status Display Builder
struct DeviceStatusViewBuilder {
    /// Generate status display configuration
    static func build(for state: ConnectionState) -> (text: String, color: Color) {
        switch state {
        case .connected:
            return ("已連接 Connected", .green)
        case .connecting:
            return ("搜尋中 Searching", .orange)
        default:
            return ("未連接 Disconnected", .gray)
        }
    }
}

// MARK: - View Components Extension
private struct EnhancedDeviceListItem: View {
    @ObservedObject var device: BluetoothDevice
    let manager: BluetoothManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Signal strength icon
            SignalStrengthIcon(rssi: device.rssi)
            
            // Device info
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                Text(DeviceStatusViewBuilder.build(for: device.state).text)
                    .font(.caption)
            }
            
            Spacer()
            
            // Connection control button
            ConnectionControlButton(device: device, manager: manager)
        }
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
    }
    
    /// Handle tap event
    private func handleTap() {
        if device.state == .disconnected {
            manager.immediateConnect(device)
        } else {
            manager.forceDisconnect(device)
        }
        HapticFeedbackController.trigger(.connectionSuccess)
    }
}

// MARK: - Connection Control Button
struct ConnectionControlButton: View {
    @ObservedObject var device: BluetoothDevice
    let manager: BluetoothManager
    
    var body: some View {
        let config = DeviceStatusViewBuilder.build(for: device.state)
        
        Button(action: performAction) {
            Text(config.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(config.color)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    /// Perform connect/disconnect action
    private func performAction() {
        if device.state == .disconnected {
            manager.immediateConnect(device)
        } else {
            manager.forceDisconnect(device)
        }
    }
}
