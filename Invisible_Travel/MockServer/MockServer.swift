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
    
    init(port: UInt16) {
        self.port = NWEndpoint.Port(rawValue: port)!
    }
    
    
    // simulating generating data
    var statusGenerator: () -> StatusMessage? = {
        StatusMessage(
            batteryLevel: Int.random(in: 20...100),
            isCharging: Bool.random(),
            network: Int.random(in: -90...50),
            uptime: Double.random(in: 0...86400),
            firmwareVersion: "Mock-1.0.0"
        )
    }
}


func start() throws {
    let para = NWParameters(tls: nil)
    para.allowLocalEndpointReuse = true
    para.includePeerToPeer = false
    
    listener = try NWListener(using: para, on: port)
    
    listener?.stateUpdateHandler = { newState in
        switch newState {
        
        }
    }
}
