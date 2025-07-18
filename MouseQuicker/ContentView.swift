//
//  ContentView.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            // 使用应用图标而不是系统符号
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
            } else {
                // 后备方案
                Image(systemName: "circle.grid.3x3")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 48))
            }

            Text("MouseQuicker")
                .font(.title)
                .fontWeight(.bold)

            Text("鼠标快捷键菜单工具")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("长按鼠标中键显示圆形快捷键菜单")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
