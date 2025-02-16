//
//  WSDelegateHandler.swift
//  Invisible_Travel
//
//  Created by kc on 16/2/2025.
//

// WSDelegateHandler.swift
private class WSDelegateHandler: NSObject, WSManagerDelegate {
    func didReceiveFrame(_ frameData: Data) {
        // 正确的视频处理流程
        VideoProcessor.shared.processFrameAsync(frameData) { image in
            if let image = image {
                ImageCache.shared.updateLatestImage(image)
                LogManager.shared.logVideoFrame(frameData)  // 记录原始帧数据
            }
        }
    }
}
