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
    /// Regular expression pattern for audio device name matching
    private let namePattern = "(?i)audio|headset"
    
    /// Applies name filtering using predefined regex pattern
    /// - Parameter name: Device name to validate
    /// - Returns: Boolean indicating name match status
    func applyNameFilter(_ name: String) -> Bool {
        return name.range(of: namePattern, options: .regularExpression) != nil
    }
}

// MARK: - Scan Scheduler
final class ScanScheduler {
    /// Scan interval in seconds
    private let interval: TimeInterval = 30
    private weak var manager: BluetoothManager?
    
    /// Initializes with BluetoothManager reference
    init(manager: BluetoothManager) {
        self.manager = manager
    }
    
    /// Starts automated scan refresh cycle
    func startAutoRefresh() {
        guard let manager = manager else { return }
        
        manager.stopScan()
        manager.startScan()
        scheduleNextRefresh()
    }
    
    /// Schedules next scan iteration
    private func scheduleNextRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.startAutoRefresh()
        }
    }
}

// MARK: - Haptic Feedback Controller
enum HapticFeedbackType {
    case connectionSuccess
    case timeout
}

final class HapticFeedbackController {
    /// Triggers haptic feedback based on event type
    /// - Parameter type: Feedback event category
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
    /// Processes discovered peripherals with enhanced filtering
    func enhancedProcessDiscoveredPeripheral(
        _ peripheral: CBPeripheral,
        rssi: NSNumber,
        filterEngine: DeviceFilterEngine
    ) {
        guard let deviceName = peripheral.name else { return }
        
        let isValidName = filterEngine.applyNameFilter(deviceName)
        let isValidRSSI = rssi.intValue >= -100
        
        if isValidName && isValidRSSI {
            processDiscoveredPeripheral(peripheral, rssi: rssi)
        }
    }
    
    /// Initiates immediate connection to specified device
    /// - Parameter device: Target Bluetooth device
    func immediateConnect(_ device: BluetoothDevice) {
        guard let peripheral = device.peripheral else { return }
        
        // Reset connection state
        invalidateTimer(for: device.id)
        device.state = .connecting
        device.lastConnectionAttempt = Date()
        
        // Initiate system connection
        (centralManager as CBCentralManager).connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
        
        startConnectionTimer(for: device)
    }
    
    /// Forces disconnection of specified device
    /// - Parameter device: Target Bluetooth device
    func forceDisconnect(_ device: BluetoothDevice) {
        guard let peripheral = device.peripheral else { return }
        
        // Cleanup resources
        invalidateTimer(for: device.id)
        peripheral.delegate = nil
        centralManager.cancelPeripheralConnection(peripheral)
        
        // Update device state
        updateDeviceState(peripheral, state: .disconnected)
    }
    
    /// Invalidates connection timer for device
    /// - Parameter deviceId: UUID of target device
    func invalidateTimer(for deviceId: UUID) {
        connectionTimeoutTimers[deviceId]?.invalidate()
    }
}

// MARK: - Status Display Builder
struct DeviceStatusViewBuilder {
    /// Generates display configuration for connection state
    /// - Parameter state: Current connection state
    /// - Returns: Tuple containing display text and color
    static func build(for state: ConnectionState) -> (text: String, color: Color) {
        switch state {
        case .connected:
            return ("Connected", .green)
        case .connecting:
            return ("Searching", .orange)
        default:
            return ("Disconnected", .gray)
        }
    }
}

// MARK: - View Components
private struct EnhancedDeviceListItem: View {
    @EnvironmentObject var manager: BluetoothManager
    let deviceId: UUID
    
    var body: some View {
        if let device = manager.discoveredDevices.first(where: { $0.id == deviceId }) {
            HStack(spacing: 12) {
                SignalStrengthIndicator(rssi: device.rssi)
                
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.headline)
                    Text(DeviceStatusViewBuilder.build(for: device.state).text)
                        .font(.caption)
                }
                
                Spacer()
                
                ConnectionControlButton(deviceId: device.id)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: handleTap)
        }
    }
    
    private func handleTap() {
        guard let device = manager.discoveredDevices.first(where: { $0.id == deviceId }) else { return }
        
        if device.state == .disconnected {
            manager.immediateConnect(device)
        } else {
            manager.forceDisconnect(device)
        }
        HapticFeedbackController.trigger(.connectionSuccess)
    }
}

struct ConnectionControlButton: View {
    @EnvironmentObject var manager: BluetoothManager
    let deviceId: UUID
    
    var body: some View {
        if let device = manager.discoveredDevices.first(where: { $0.id == deviceId }) {
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
    }
    
    private func performAction() {
        guard let device = manager.discoveredDevices.first(where: { $0.id == deviceId }) else { return }
        
        if device.state == .disconnected {
            manager.immediateConnect(device)
        } else {
            manager.forceDisconnect(device)
        }
    }
}

// MARK: - Coordinator Protocol
protocol BluetoothManagerDelegate: AnyObject {
    func didProcessPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber)
    func didStartConnectionTimer(for device: BluetoothDevice)
}

extension BluetoothManager {
    weak var delegate: BluetoothManagerDelegate?
    
    private func processDiscoveredPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber) {
        delegate?.didProcessPeripheral(peripheral, rssi: rssi)
    }
    
    private func startConnectionTimer(for device: BluetoothDevice) {
        delegate?.didStartConnectionTimer(for: device)
    }
}

final class BLECoreCoordinator: BluetoothManagerDelegate {
    private weak var manager: BluetoothManager?
    
    init(manager: BluetoothManager) {
        self.manager = manager
        self.manager?.delegate = self
    }
    
    func didProcessPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber) {
        manager?.processDiscoveredPeripheral(peripheral, rssi: rssi)
    }
    
    func didStartConnectionTimer(for device: BluetoothDevice) {
        manager?.startConnectionTimer(for: device)
    }
}
