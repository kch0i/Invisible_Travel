//
//  LogView.swift
//  Invisible_Travel
//
//  Created by kc on 16/2/2025.
//

struct LogView: View {
    @ObservedObject var logManager = LogManager.shared
    
    var body: some View {
            ScrollViewReader { proxy in
                List {
                    ForEach(logManager.entries) { entry in
                        LogEntryView(entry: entry)  // 添加缺失的视图主体
                            .id(entry.id)
                            .contextMenu {
                                if case .jpegFrame(let data) = entry.type {
                                    Button("Export Frame") {  // 修正Button名称
                                        exportFrame(data)
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func exportFrame(_ data: Data) {
        if let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
    
    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        if let latest = logManager.entries.first {
            proxy.scrollTo(latest.id, anchor: .top)
        }
    }
}

struct logEntryView: View {
    let entry: logEntryView
    var body: some View {
        VStack(alignment: .leading) {
            HeaderSection(entry: entry)
            DataContentSection(entry: entry)
        }
        .padding(.vertical, 8)
    }
    
    struct HeaderSection: View {
        let entry: logEntry
        
        var body: some View {
            HStack {
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                DirectionIndicator(direction: entry.direction)
                DataTypeLabel(atype: entry.type)
            }
        }
    }
    
    struct DataContentSection: View {
        let entry: LogEntry
            
        var body: some View {
            Group {
                switch entry.type {
                case .jpegFrame(let data):
                    VideoFramePreview(data: data)
                case .status(let status):
                    StatusView(status: status)
                case .plainText(let text):
                    Text(text)
                case .rawData(_):
                    RawDataIndicator()
                }
            }
        }
    }
}
