//
//  WSDataType.swift
//  Invisible_Travel
//
//  Created by kc on 16/2/2025.
//

enum WSDataType: Equatable {
    case status(StatusMessage)
    case plainText(String)
    case jpegFrame(Data)
    case rawData(Data)
    
    var description: String {
        switch self {
        case .status: return "Status"
        case .plainText: return "Text"
        case .jpegFrame: return "VideoFrame"
        case .rawData: return "Binary"
        }
    }
}
