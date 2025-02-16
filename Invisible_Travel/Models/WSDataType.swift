//
//  WSDataType.swift
//  Invisible_Travel
//
//  Created by kc on 16/2/2025.
//

enum WSDataType: Equatable {
    case status(StatusMessage)
    case plainText(String)
    case jepgFrame(Data)
    case rawData(Data)
    
    var descrtiption: String {
        switch self {
        case .status: return "Status"
        case .plainText: return "Text"
        case .jepgFrame: return "VideoFrame"
        case .rawData: return "Binary"
        }
    }
}
