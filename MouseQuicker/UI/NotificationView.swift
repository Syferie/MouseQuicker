//
//  NotificationView.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import SwiftUI

/// Toast-style notification view
struct NotificationView: View {
    let title: String
    let message: String
    let type: NotificationType
    let onDismiss: () -> Void
    
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(0.8))
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 1.0
            }
            
            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
    
    private var iconName: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .success: return Color.green.opacity(0.2)
        case .info: return Color.blue.opacity(0.2)
        case .warning: return Color.yellow.opacity(0.2)
        case .error: return Color.red.opacity(0.2)
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .success: return Color.green
        case .info: return Color.blue
        case .warning: return Color.yellow
        case .error: return Color.red
        }
    }
    
    private var textColor: Color {
        switch type {
        case .success: return Color.primary
        case .info: return Color.primary
        case .warning: return Color.primary
        case .error: return Color.primary
        }
    }
}

/// View modifier to add notification overlay
struct NotificationModifier: ViewModifier {
    @ObservedObject var errorHandler = ErrorHandler.shared
    @State private var showingNotification = false
    @State private var notificationData: (title: String, message: String, type: NotificationType)?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if showingNotification, let data = notificationData {
                        VStack {
                            NotificationView(
                                title: data.title,
                                message: data.message,
                                type: data.type,
                                onDismiss: {
                                    showingNotification = false
                                }
                            )
                            .padding()
                            
                            Spacer()
                        }
                    }
                }
            )
            .onReceive(NotificationCenter.default.publisher(for: .errorOccurred)) { notification in
                if let error = notification.object as? AppError {
                    notificationData = (error.title, error.message, .error)
                    showingNotification = true
                }
            }
    }
}

extension View {
    func withNotifications() -> some View {
        modifier(NotificationModifier())
    }
}

#Preview {
    VStack {
        NotificationView(
            title: "操作成功",
            message: "快捷键已成功添加到菜单",
            type: .success,
            onDismiss: {}
        )
        
        NotificationView(
            title: "提示信息",
            message: "请先配置快捷键",
            type: .info,
            onDismiss: {}
        )
        
        NotificationView(
            title: "警告",
            message: "快捷键可能与系统快捷键冲突",
            type: .warning,
            onDismiss: {}
        )
        
        NotificationView(
            title: "错误",
            message: "无法执行快捷键，请检查权限设置",
            type: .error,
            onDismiss: {}
        )
    }
    .padding()
}
