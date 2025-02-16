//
//  LogManager.swift
//  Invisible_Travel
//
//  Created by kc on 16/2/2025.
//

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: WSDataType
    let direction: Direction
    let metaData: [String: String]?
    
    enum Direction {
        case sent, received
    }
}


class LogManager: ObservableObject {
    static let shared = LogManager()
    @Published private(set) var entries = [LogEntry]()
    
    // Video record
    func logVideoFrame(_ frameData: Data) {
        let entry = logEntry(
            timestamp: Date(),
            type: .jpegFrame(frameData),
            direction: .received,
            metaData: ["size": "\(frameData.count) bytes"]
        )
        addEntry(entry)
    }
    
    // general record method
    func log(_ dataType: WSDataType, direction: LogEntry.Direction = .received) {
        let entry = LogEntry(
                    timestamp: Date(),
                    type: dataType,
                    direction: direction
                )
                addEntry(entry)
    }
    
    private func addEntry(_ entry: LogEntry) {
        DispatchQueue.main.async { [weak self] in
            self?.entries.insert(entry, at: 0)
            self?.applyRetentionPolicy()
        }
    }
    
    private func applyRetentionPolicy() {
        if entries.count > 500 {
            entries = Array(entries[0..<500])
        }
    }
}
