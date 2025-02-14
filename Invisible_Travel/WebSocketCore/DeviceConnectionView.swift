//
//  DeviceConnectionView.swift
//  Invisible_Travel
//
//  Created by kc on 14/2/2025.
//

import Foundation


// M: WebSocket Event processing

struct DeviceConnectionView: WSManagerDelegate {
    func didReceiveDeviceStatus(_ status: DeviceStatus) {
        print("Received status:", status)
        // update UI or processing data
    }
    
    func didReceiveVideoFrame(_ image: UIImage) {
        print("Received video frame:", image.size)
        // processing video (it can send to others)
    }
}
