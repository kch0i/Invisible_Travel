//
//  Untitled.swift
//  UUIDDDD
//
//  Created by Ip Argus on 20/2/2025.
//

import CoreBluetooth
import SwiftUI

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    var centralManager: CBCentralManager?
    
    // ✅ 使用 Dictionary 來避免重複設備
    @Published var discoveredDevices: [UUID: (name: String, rssi: Int, services: [CBUUID])] = [:]
    @Published var connectionStatus: String = "未連接"
    @Published var filterText: String = "" // 🔍 搜尋欄文字
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("✅ 藍牙已開啟，開始掃描...")
            startScanning()
        } else {
            connectionStatus = "❌ 藍牙未開啟"
        }
    }
    
    func startScanning() {
        discoveredDevices.removeAll() // 清除舊的數據
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceName = peripheral.name ?? "未知設備"
        let deviceUUID = peripheral.identifier
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        
        DispatchQueue.main.async {
            if self.discoveredDevices[deviceUUID] == nil { // ✅ 避免重複加入
                self.discoveredDevices[deviceUUID] = (name: deviceName, rssi: RSSI.intValue, services: serviceUUIDs)
                print("🔹 發現設備: \(deviceName) | UUID: \(deviceUUID) | RSSI: \(RSSI) | 服務 UUIDs: \(serviceUUIDs)")
            }
        }
    }
    
    // 🔍 根據搜尋文字過濾設備
    var filteredDevices: [(UUID, (name: String, rssi: Int, services: [CBUUID]))] {
        let sortedDevices = discoveredDevices.sorted { $0.value.rssi > $1.value.rssi } // 按 RSSI 排序
        if filterText.isEmpty {
            return sortedDevices
        } else {
            return sortedDevices.filter { $0.value.name.lowercased().contains(filterText.lowercased()) }
        }
    }
}
