# BlindApp Sample (Unfinished)

## 簡介
BlindApp 是一款專為視障人士設計的 iOS 應用，提供語音輸入、語音回饋和簡化的交互界面。

## 功能
- VoiceOver 支援
- 按鍵震動和音效提示

## 文件結構
- `App/`: 主應用代碼
- `Tests/`: 單元測試代碼
- `Resources/`: 圖片、音效等資源文件

'''mermaid
sequenceDiagram
    Websocket Server->>WSManager: 发送二进制数据流
    WSManager->>Video Processor: 提取帧数据包
    Video Processor->>Image Cache: 解码后的UIImage
    Image Cache->>VideoPreview: 实时显示预览
    WSManager->>LogManager: 记录原始帧数据
'''
