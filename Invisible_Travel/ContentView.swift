//
//  ContentView.swift
//  Invisible_Travel
//
//  Created by kc on 10/12/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                // 第一部分
                Section {
                    SettingRow(icon: "globe", title: "Language / 語言", detail: "English")
                    SettingRow(icon: "location.fill", title: "Travel Guide")
                    SettingRow(icon: "battery.50", title: "Device Information")
                    SettingRow(icon: "wifi", title: "Device Connection")
                    SettingRow(icon: "headphones", title: "Headphone Connection")
                    SettingRow(icon: "sun.max", title: "Weather Information")
                    SettingRow(icon: "textformat.size", title: "Colour Filter")
                }
            
            }
            .navigationTitle("Invisible Travel")
            .listStyle(InsetGroupedListStyle()) // 組合樣式，模仿設置界面
        }
    }
}

struct SettingRow: View {
    var icon: String
    var title: String
    var detail: String? = nil
    var isToggle: Bool = false
    
    var body: some View {
        HStack {
            // 圖標
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            
            // 主標題
            Text(title)
                .font(.title2) // 調整字體大小
                .foregroundColor(.primary)
            
            Spacer()
            
            // 詳細內容或切換按鈕
            if let detail = detail {
                Text(detail)
                    .foregroundColor(.gray)
                    .font(.title3)
            } else if isToggle {
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
            }
        }
        .padding(.vertical, 10) // 增加行高度
        .accessibilityElement(children: .combine) // VoiceOver 支持
    }
}

#Preview {
    ContentView()
}
