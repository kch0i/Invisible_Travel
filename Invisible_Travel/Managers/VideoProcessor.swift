//
//  VideoProcessor.swift
//  Invisible_Travel
//
//  Created by kc on 16/2/2025.
//

class VideoProcessor {
    static let shared = VideoProcessor()
    private let decodeQueue = DispatchQueue(label: "video.decode", qos: .userInteractive)
    private var activeTasks = [UUID]()
    
    func processFrameAsync(_ frameData: Data, completion: @escaping (UIImage?) -> Void) {
        let taskID = UUID()
        activeTasks.append(taskID)
        
        decodeQueue.async { [weak self] in
            guard self?.activeTasks.contains(taskID) == true else { return }
            
            // GPU decode
            guard let image = UIImage(data: frameData)?.preparingForDisplay(),
                  let resizedImage = self?.resizeImage(image, maxDimension: 800) else {
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(resizedImage)
                self?.activeTasks.removeAll { $0 == taskID }
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let ratio = maxDimension / max(image.size.width, image.size.height)
        let newSize = CGSize(width: image.size.width * ratio,
                             height: image.size.height * ratio)
        
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
