//
//  WSManager.swift
//  Invisible_Travel
//
//  Created by kc on 13/2/2025.
//

import Foundation
import Combine
import Starscream
import UIKit


protocol WSManagerDelegate: AnyObject {
    func connectionStatusDidChange(_ isConnected: Bool)
    func didReceiveStatusMessage(_ status: StatusMessage)
    func didReceiveVideoFrame(_ data: UIImage)
}
    


final class WSManager: ObservableObject, WebSocketDelegate {
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3
    
    // Add connection status enumeration to enhance readability
    enum ConnectionState {
        case connected, disconnected, connecting
    }
    
    @Published private(set) var connectionState: ConnectionState = .disconnected
    
    // M: Publish property
    // check connection (Combine)
    @Published private(set) var isConnected = false
    // Last error msg
    @Published private(set) var lastError: String?
    
    // M: Private property
    // Websocket items
    private var socket: WebSocket?
    // delegate items
    private var delegate: WSManagerDelegate?
    // Queue
    private let serialQueue = DispatchQueue(label: "com.websocket.serial")
    
    // M: Start
    
    // single item
    static let shared = WSManager()
    private init() {}
    
    // M: connection management
    
    // conect to server
    // para: urlString eg.(ws://ip:port), delegate
    func connect(to urlString: String, delegate: WSManagerDelegate) {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            // disconnect the present connection
            self.socket?.disconnect()
            
            //url check
            guard let url = URL(string: urlString) else {
                self.updateError("Invalid URL: \(urlString)")
                return
            }
            
            // setting request
            let request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                timeoutInterval: 10
            )
            
            // initialise websocket
            self.socket = WebSocket(request: request)
            self.socket?.delegate = self
            self.socket?.connect()
            
            self.delegate = delegate
        }
    }
    // disconnect automatically
    func disconnect() {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            self.socket?.disconnect()
            self.socket = nil
            self.isConnected = false
            self.delegate = nil
        }
    }
    
    // M: data sent
    
    // command sent
    // para command
    func sendCommand(_ command: DeviceInfoCommand) {
        serialQueue.async { [weak self] in
            guard let self = self, self.isConnected else {
                self?.updateError("Cant send command: Not connected")
                return
            }
            
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .sortedKeys
                let data = try encoder.encode(command)
                self.socket?.write(data: data)
            } catch {
                self.updateError("Encode failed: \(error.localizedDescription)")
            }
        }
    }
    
    // M: Error processing
    private func updateError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = message
        }
    }
    
    // M: WebSocketDelegate
    
    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        switch event{
        case .connected(let headers):
            handleConnected(headers: headers)
            
        case .disconnected(let reason, let code):
            handleDisconnected(reason: reason, code: code)
            
        case .text(let text):
            handleTextMessage(text)
        
        case .binary(let data):
                    handleBinaryData(data)
            
        case .error(let error):
            updateError("WebSocket error: \(error?.localizedDescription ?? "Unknown")")
            
        default:
            break
        }
    }
    
    // M: case processing
    
    private func handleConnected(headers: [String: String]) {
        serialQueue.async { [weak self] in
            self?.isConnected = true
            self?.updateError(nil ?? "")
            print("WebSocket connected. Headers: \(headers)")
        }
    }
    
    private func handleDisconnected(reason: String, code: UInt16) {
        serialQueue.async { [weak self] in
            self?.isConnected = false
            let message = "Disconnected (\(code): \(reason)"
            self?.updateError(message)
            self?.scheduleReconnect()
        }
    }
    
    private func handleTextMessage(_ text: String) {
        do {
            let data = Data(text.utf8)
            let status = try JSONDecoder().decode(StatusMessage.self, from: data)
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didReceiveStatusMessage(status)
            }
        } catch {
            updateError("Status decode failed: \(error.localizedDescription)")
        }
    }
    
    private func handleBinaryData(_ data: Data) {
        guard let image = UIImage(data: data) else {
            updateError("Invalid image data received")
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didReceiveVideoFrame(image)
        }
    }
    
    
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else { return }
        reconnectAttempts += 1
        DispatchQueue.global().asyncAfter(deadline: .now() + pow(2, Double(reconnectAttempts))) {
            self.socket?.connect()
        }
    }
    
    
}

// M: data model
struct DeviceInfoCommand: Codable {
    enum ActionType: String, Codable {
        case requestStatus = "req_status"
        case setResolution = "set_res"
        case reboot = "reboot"
    }
    
    let action: ActionType
    var width: Int?
    var height: Int?
    
    init(action: ActionType, resolution: CGSize? = nil) {
        self.action = action
        if let resolution = resolution {
            self.width = Int(resolution.width)
            self.height = Int(resolution.height)
        }
    }
}

struct StatusMessage: Codable {
    struct NetworkInfo: Codable {
        let signalDBM: Int
        let channel: Int
    }
    
    let batteryLevel: Int
    let isCharging: Bool
    let network: NetworkInfo
    let uptime: TimeInterval
    let firmwareVersion: String
}

