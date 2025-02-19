//
//  Untitled.swift
//  Bluetooth2.0
//
//  Created by Ip Argus on 18/2/2025.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @Published var isConnected = false
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var isBluetoothReady = false
    
    private let targetPeripheralUUID = UUID(uuidString: "A83A38FA-6F8E-AFDB-FA91-88BFA848DE3B")
    
    // A83A38FA-6F8E-AFDB-FA91-88BFA848DE3B
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
           DispatchQueue.main.async {
               switch central.state {
               case .poweredOn:
                   print("bluetooth opened start scanning")
                   self.isBluetoothReady = true
               case .poweredOff:
                   print("bluetooth closed please open it")
                   self.isBluetoothReady = false
               case .unauthorized:
                   print("missing permissions")
               default:
                   print("unknow state：\(central.state.rawValue)")
               }
           }
       }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.identifier == targetPeripheralUUID {
            DispatchQueue.main.async {
                print(" 找到：\(peripheral.name ?? "未知設備")")
                
                // 停止掃描並連接
                self.centralManager.stopScan()
                self.targetPeripheral = peripheral
                self.targetPeripheral?.delegate = self
                self.centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            print("✅ connected to ")
            self.isConnected = true
            print("the result is :", self.isConnected)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            print("❌ disconnected to")
            self.isConnected = false
        }
    }
    
    func toggleConnection(_ shouldConnect: Bool) {
        DispatchQueue.main.async {
            if shouldConnect {
                self.connectToDevice()
            } else {
                self.disconnectDevice()
            }
        }
    }
    private func connectToDevice() {
            guard isBluetoothReady else {
                print("bluetooth not ready")
                return
            }
        
        guard targetPeripheralUUID != nil else {
                print("error")
                return
            }
            
            print("start scanning")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
            
    private func disconnectDevice() {
            guard let peripheral = targetPeripheral else {
                print("no connected device")
                return
            }
            
            if peripheral.state == .connected {
                centralManager.cancelPeripheralConnection(peripheral)
                print("disconnect with  \(peripheral.name ?? "未知設備")")
            } else {
                print("have been disconnected")
            }
        }
    }
