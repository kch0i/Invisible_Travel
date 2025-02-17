//
//  BLE.swift
//  Invisible_Travel
//
//  Created by kc on 17/2/2025.
//

import Foundation
import CoreBluetooth
import SwiftUI

// MARK: - Bluetooth Rights Handling Protocol
protocol BluetoothPermissionHandler{
    func handleBluetoothUnauthorized()
    func handleBluetoothPoweredOff()
}

// MARK: - Bluetooth connection status enumeration
enum ConnectionState: Int {
    case disconnected
    case connecting
    case connected
}

// MARK: - Bluetooth device data model
class BluetoothDevice: Identifiable {
    let id: UUID
    weak var peripheral: CBPeripheral?
    var name: String
    var rssi: Int
    var state: ConnectionState
    var lastConnectionAttempt: Date?  // Connection time tracking
    
    init(peripheral: CBPeripheral, rssi: Int) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.name = peripheral.name ?? "Unknown Device"
        self.rssi = rssi
        self.state = .disconnected
    }
}

// MARK: - Bluetooth Core Manager
class BluetoothManager: NSObject, ObservableObject {
    // Data Release Attributes
    @Published var discoveredDevices: [BluetoothDevice] = []
    @Published var isScanning: Bool = false
    @Published var authorizationStatus: CBManagerAuthorization = .notDetermined
    
    // Bluetooth core components
    private var centralManager: CBCentralManager!
    private let scanTimeout: TimeInterval = 3.0
    private var connectionTimeoutTimers: [UUID: Timer] = [:]
    
    // dependency injection
    var permissionHandler: BluetoothPermissionHandler?
    
    // Initialisation methods
    override init() {
        super.init()
        initializeCentralManager()
    }
    
    // MARK: - public method
    func startScan() {
        guard centralManager.state == .poweredOn else {
            handlePreScanningState()
            return
        }
        
        resetScanningState()
        startBLEScanning()
        setupScanTimeout()
    }
    
    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func toggleConnection(for device: BluetoothDevice) {
        guard let peripheral = device.peripheral else { return }
        
        switch device.state {
        case .disconnected:
            beginConnectionProcess(device, peripheral: peripheral)
        default:
            cancelConnection(peripheral)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handleBluetoothStateUpdate(central)
    }
    
    func centralManager(_ central: CBCentralManager,
                        willRestoreState dict: [String: Any]) {
        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral]
        else {return}
        
        peripherals.forEach {
            $0.delegate = self
            discoveredDevices.append(BluetoothDevice(peripheral: $0, rssi: -1))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        handleSuccessfulConnection(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        handleFailedConnection(peripheral, error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        handleDisconnection(peripheral, error: error)
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        services.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        characteristics.filter { $0.properties.contains(.notify) }.forEach {
            peripheral.setNotifyValue(true, for: $0)
        }
    }
}

// MARK: - private method extension
private extension BluetoothManager {
    func initializeCentralManager() {
        let options: [String: Any] = [
            CBCentralManagerOptionShowPowerAlertKey: false,
            CBCentralManagerOptionRestoreIdentifierKey: "com.yourcompany.InvisibleTravel"
        ]
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func handleBluetoothStateUpdate(_ central: CBCentralManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.authorizationStatus = CBCentralManager.authorization
            
            switch central.state {
            case .unauthorized:
                self.handleAuthorizationIssue()
            case .poweredOff:
                self.permissionHandler?.handleBluetoothPoweredOff()
            case .poweredOn:
                print("Bluetooth ready")
            default:
                print("Bluetooth status changes: \(central.state.rawValue)")
            }
        }
    }
    
    func handleAuthorizationIssue() {
        let status = CBCentralManager.authorization
        switch status {
        case .denied:
            permissionHandler?.handleBluetoothUnauthorized()
        case .restricted:
            print("Device restricts Bluetooth access")
        default: break
        }
    }
    
    func processDiscoveredPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber) {
        guard rssi.intValue >= -100 else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let validRSSI = rssi.intValue
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                self.discoveredDevices[index].rssi = validRSSI
            } else {
                self.addNewDevice(peripheral, rssi: validRSSI)
            }
        }
    }
    
    func addNewDevice(_ peripheral: CBPeripheral, rssi: Int) {
        let newDevice = BluetoothDevice(peripheral: peripheral, rssi: rssi)
        discoveredDevices.append(newDevice)
        
        if discoveredDevices.count > 10 {
            discoveredDevices.sort { $0.rssi > $1.rssi }
            discoveredDevices.removeLast()
        }
    }
    
    func beginConnectionProcess(_ device: BluetoothDevice, peripheral: CBPeripheral) {
        device.state = .connecting
        device.lastConnectionAttempt = Date()
        centralManager.connect(peripheral, options: nil)
        startConnectionTimer(for: device)
    }
    
    func cancelConnection(_ peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
        connectionTimeoutTimers.removeValue(forKey: peripheral.identifier)?.invalidate()
    }
    
    func startConnectionTimer(for device: BluetoothDevice) {
        let timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.handleConnectionTimeout(for: device)
        }
        connectionTimeoutTimers[device.id] = timer
    }
    
    func handleConnectionTimeout(for device: BluetoothDevice) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let index = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) else { return }
            
            self.discoveredDevices[index].state = .disconnected
            self.connectionTimeoutTimers.removeValue(forKey: device.id)
            
            if let peripheral = device.peripheral {
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func handleSuccessfulConnection(_ peripheral: CBPeripheral) {
        updateDeviceState(peripheral, state: .connected)
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "110B")])
    }
    
    func handleFailedConnection(_ peripheral: CBPeripheral, error: Error?) {
        updateDeviceState(peripheral, state: .disconnected)
        print("Connection failed: \(error?.localizedDescription ?? "")")
    }
    
    func handleDisconnection(_ peripheral: CBPeripheral, error: Error?) {
        updateDeviceState(peripheral, state: .disconnected)
        print("Disconnect: \(error?.localizedDescription ?? "")")
    }
    
    func updateDeviceState(_ peripheral: CBPeripheral, state: ConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let index = self.discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) else { return }
            
            self.discoveredDevices[index].state = state
            self.discoveredDevices[index].lastConnectionAttempt = (state == .connecting) ? Date() : nil
        }
    }
    
    func handlePreScanningState() {
        switch centralManager.state {
        case .poweredOff:
            permissionHandler?.handleBluetoothPoweredOff()
        case .unauthorized:
            permissionHandler?.handleBluetoothUnauthorized()
        default:
            print("Bluetooth unready: \(centralManager.state.rawValue)")
        }
    }
    
    func resetScanningState() {
        discoveredDevices.removeAll()
        isScanning = true
    }
    
    func startBLEScanning() {
        centralManager.scanForPeripherals(
            withServices: [CBUUID(string: "110B")],
            options: [CBCentralManagerRestoredStateScanOptionsKey: false]
        )
    }
    
    func setupScanTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + scanTimeout) { [weak self] in
            self?.stopScan()
        }
    }
}

// MARK: - SwiftUI
@MainActor
struct HeadphoneConnectionView: View {
    @StateObject private var btManager = BluetoothManager()
    @State private var showBluetoothAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            StatusHeaderView(manager: btManager)
            DeviceListView(manager: btManager)
            ControlButtonsView(manager: btManager)
        }
        .padding()
        .onAppear(perform: initializeBluetooth)
        .alert("Bluetooth Privilege", isPresented: $showBluetoothAlert) {
            AlertButtons
        }
    }
    
    private var AlertButtons: some View {
        Group {
            Button("To setting") { openAppSettings() }
            Button("cancel", role: .cancel) { }
        }
    }
    
    private func initializeBluetooth() {
        btManager.permissionHandler = self
        btManager.startScan()
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

extension HeadphoneConnectionView: BluetoothPermissionHandler {
    func handleBluetoothUnauthorized() {
        alertMessage = "Requires Bluetooth privileges to connect to the device, please go to Setting Enabling Privileges."
        showBluetoothAlert = true
    }
    
    func handleBluetoothPoweredOff() {
        alertMessage = "Please turn on Bluetooth for device connection"
        showBluetoothAlert = true
    }
}

// MARK: - subview component
private struct StatusHeaderView: View {
    @ObservedObject var manager: BluetoothManager
    
    var body: some View {
        HStack {
            Image(systemName: "wave.3.right.circle")
                .foregroundColor(manager.isScanning ? .blue : .gray)
            Text(manager.isScanning ? "Scanning..." : "Has found \(manager.discoveredDevices.count)  devices")
                .font(.subheadline)
        }
    }
}

// Device List Component
private struct DeviceListView: View {
    @ObservedObject var manager: BluetoothManager
    
    var body: some View {
        List(manager.discoveredDevices) { device in
            HStack(spacing: 12) {
                // Signal Strength Icon
                SignalStrengthIcon(rssi: device.rssi)
                
                // Device Name
                Text(device.name)
                    .font(.body)
                    .lineLimit(1)
                
                Spacer()
                
                // Connection Status Indicator
                ConnectionStatusIndicator(state: device.state)
                
                // Connection Button
                Button(action: { manager.toggleConnection(for: device) }) {
                    Text(buttonTitle(for: device.state))
                        .font(.callout)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(buttonBackground(for: device.state))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
        .listStyle(.plain)
    }
    
    // Button Title Logic
    private func buttonTitle(for state: ConnectionState) -> String {
        switch state {
        case .connected: return "disconnect"
        case .connecting: return "connecting"
        default: return "connect"
        }
    }
    
    // Button Background Logic
    private func buttonBackground(for state: ConnectionState) -> Color {
        switch state {
        case .connected: return .red
        case .connecting: return .orange
        default: return .blue
        }
    }
}

// Control Buttons Component
private struct ControlButtonsView: View {
    @ObservedObject var manager: BluetoothManager
    
    var body: some View {
        HStack(spacing: 20) {
            // Rescan Button
            Button(action: {
                manager.stopScan()
                manager.startScan()
            }) {
                Label("Rescan", systemImage: "arrow.clockwise")
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // Disconnect All Button
            Button(action: {
                manager.discoveredDevices.forEach { device in
                    if device.state != .disconnected {
                        manager.toggleConnection(for: device)
                    }
                }
            }) {
                Label("Disconnect All", systemImage: "xmark.circle")
                    .padding(10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Custom Subcomponents

/// Signal Strength Icon Component
struct SignalStrengthIcon: View {
    let rssi: Int
    
    var body: some View {
        let (iconName, color) = signalLevel
        Image(systemName: iconName)
            .foregroundColor(color)
            .imageScale(.large)
    }
    
    // Signal Level Calculation
    private var signalLevel: (String, Color) {
        switch rssi {
        case ..<(-80): return ("wifi.slash", .gray)
        case -80...(-60): return ("wifi.exclamationmark", .orange)
        default: return ("wifi", .green)
        }
    }
}

/// Connection Status Indicator
struct ConnectionStatusIndicator: View {
    let state: ConnectionState
    
    var body: some View {
        Circle()
            .frame(width: 12, height: 12)
            .foregroundColor(indicatorColor)
    }
    
    private var indicatorColor: Color {
        switch state {
        case .connected: return .green
        case .connecting: return .yellow
        default: return .clear
        }
    }
}


