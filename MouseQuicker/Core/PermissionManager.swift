//
//  PermissionManager.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

/// Manager for handling system permissions required by the application
class PermissionManager: ObservableObject {
    
    /// Singleton instance
    static let shared = PermissionManager()
    
    /// Published properties for SwiftUI binding
    @Published var hasAccessibilityPermission = false
    @Published var hasInputMonitoringPermission = false
    
    private init() {
        updatePermissionStatus()
    }
    
    /// Check and update the current permission status
    func updatePermissionStatus() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        hasInputMonitoringPermission = checkInputMonitoringPermission()
    }
    
    /// Check if accessibility permission is granted
    /// - Returns: True if permission is granted
    func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Check if input monitoring permission is granted
    /// - Returns: True if permission is granted
    func checkInputMonitoringPermission() -> Bool {
        // For input monitoring, we'll use a simplified check
        // In practice, we might need to actually try creating a global event monitor
        // For now, we'll assume permission is granted and handle it during actual usage
        return true
    }
    
    /// Request accessibility permission with user prompt
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Update status after a short delay to allow for user interaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updatePermissionStatus()
        }
    }
    
    /// Request input monitoring permission by opening System Preferences
    func requestInputMonitoringPermission() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
        
        // Update status after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updatePermissionStatus()
        }
    }
    
    /// Check if all required permissions are granted
    /// - Returns: True if all permissions are available
    func hasAllRequiredPermissions() -> Bool {
        return hasAccessibilityPermission && hasInputMonitoringPermission
    }
    
    /// Show permission alert dialog
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message
    ///   - completion: Completion handler with user's choice
    func showPermissionAlert(title: String, message: String, completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "稍后")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
    
    /// Handle missing accessibility permission
    func handleMissingAccessibilityPermission() {
        showPermissionAlert(
            title: "需要辅助功能权限",
            message: "MouseQuicker需要辅助功能权限来监听全局鼠标事件。请在系统偏好设置中启用此权限。"
        ) { shouldOpenPreferences in
            if shouldOpenPreferences {
                self.requestAccessibilityPermission()
            }
        }
    }
    
    /// Handle missing input monitoring permission
    func handleMissingInputMonitoringPermission() {
        showPermissionAlert(
            title: "需要输入监控权限",
            message: "MouseQuicker需要输入监控权限来检测鼠标按键和执行快捷键。请在系统偏好设置中启用此权限。"
        ) { shouldOpenPreferences in
            if shouldOpenPreferences {
                self.requestInputMonitoringPermission()
            }
        }
    }
    
    /// Start monitoring permission changes
    func startMonitoringPermissions() {
        // Check permissions periodically
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updatePermissionStatus()
            }
        }
    }
}


