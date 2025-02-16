//
//  MockServer.swift
//  Invisible_Travel
//
//  Created by kc on 16/2/2025.
//

import Foundation
import Network

class MockServer {
    private let port: NWEndpoint.Port
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    
    init?(port: UInt16) {
        guard let validPort = NWEndpoint.Port(rawValue: port) else {
            print("Invalid port number: \(port)")
            return nil
        }
        self.port = validPort
    }
    
    
    // simulating generating data
    var statusGenerator: () -> StatusMessage? = {
        StatusMessage(
            batteryLevel: Int.random(in: 20...100),
            isCharging: Bool.random(),
            network: StatusMessage.NetworkInfo(
                signalDBM: Int.random(in: -90 ... -50),
                channel: Int.random(in: 1...11)
            ),
            uptime: Double.random(in: 0...86400),
            firmwareVersion: "Mock-1.0.0"
        )
    }
    
    
    func start() throws {
        let para = NWParameters(tls: nil)
        para.allowLocalEndpointReuse = true
        para.includePeerToPeer = false
        
        listener = try NWListener(using: para, on: port)
        
        listener?.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Mock server running on port \(self.port)")
            case .failed(let error):
                print("Server failed with error: \(error)")
            default: break
            }
        }
        
        listener?.newConnectionHandler = { [weak self] newConnection in
            self?.handleConnection(newConnection)
            newConnection.start(queue: .main)
        }
        
        listener?.start(queue: .main)
    }
    
    // handle connection
    private func handleConnection(_ connection: NWConnection) {
        connections.append(connection)
        
        connection.receiveMessage { [weak self] (data, _, _, error) in
            guard let data = data else { return }
            
            // analyse client command
            if let command = try? JSONDecoder().decode(DeviceInfoCommand.self, from: data) {
                self?.handleCommand(command, connection: connection)
            }
            
            // keep connection
            self?.handleConnection(connection)
        }
    }
    
    // handle command
    private func handleCommand(_ command: DeviceInfoCommand, connection: NWConnection) {
        switch command.action {
        case .requestStatus:
            let status = statusGenerator()
            sendData(try! JSONEncoder().encode(status), via: connection)
        
        case .setResolution:
            print("Mock: set resolution to \(command.width ?? 0) x \(command.height ?? 0)")
            
        case .reboot:
            print("Mock: Device reboot initiated")
        }
    }
    
    // data send method
    private func sendData(_ data: Data, via connection: NWConnection) {
        connection.send(
            content: data,
            completion: .contentProcessed { error in
                if let error = error {
                    print("Send error: \(error)")
                }
            }
        )
    }
}



