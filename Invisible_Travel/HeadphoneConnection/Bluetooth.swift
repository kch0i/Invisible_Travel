import SwiftUI
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    private var targetPeripheral: CBPeripheral?
    
    @Published var isConnected = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, name.contains("MKGCD") {
            targetPeripheral = peripheral
            centralManager?.stopScan()
            centralManager?.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        print("connected earphone")
    }


    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        print("earphone disconnected")
    }
}

struct BluetoothView: View {
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some View {
        VStack {
            Text("connecting bluetooth")
                .font(.title)
                .padding()

            if bluetoothManager.isConnected {
                Text("connected")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                Text("disconnect")
                    .foregroundColor(.red)
                    .font(.headline)
            }
        }
        .padding()
    }
}

import SwiftUI

struct HeadphoneConnectionView: View {
    var body: some View {
        TabView {
            BluetoothView()
                .tabItem {
                    Label("Bluetooth", systemImage: "antenna.radiowaves.left.and.right")
                }

            
        }
    }
}

#Preview {
    ContentView()
}
