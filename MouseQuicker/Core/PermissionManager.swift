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
    
    /// Published properties for SwiftUI binding (for display only)
    @Published var hasAccessibilityPermission = false

    /// Track if this is the first launch
    private let isFirstLaunchKey = "MouseQuicker_FirstLaunch"

    private init() {
        // Don't check permissions automatically
    }

    /// Check and update the current permission status (manual only)
    func updatePermissionStatus() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        print("PermissionManager: 权限状态已更新 - 辅助功能权限: \(hasAccessibilityPermission)")
    }
    
    /// Check if accessibility permission is granted
    /// - Returns: True if permission is granted
    func checkAccessibilityPermission() -> Bool {
        // Use the standard accessibility check without prompting
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let isGranted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        print("PermissionManager: Accessibility permission check result: \(isGranted)")
        print("PermissionManager: Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

        // For unsigned apps, the permission check might fail even when permission is granted
        // Try a secondary check by attempting to create a global event monitor
        if !isGranted {
            let secondaryCheck = testGlobalEventMonitor()
            print("PermissionManager: Secondary check result: \(secondaryCheck)")
            return secondaryCheck
        }

        return isGranted
    }

    /// Test if we can create a global event monitor (secondary permission check)
    private func testGlobalEventMonitor() -> Bool {
        var canCreateMonitor = false

        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { _ in
            // This block won't be called if permission is denied
        }

        if let monitor = monitor {
            canCreateMonitor = true
            NSEvent.removeMonitor(monitor)
            print("PermissionManager: Successfully created and removed test monitor")
        } else {
            print("PermissionManager: Failed to create test monitor")
        }

        return canCreateMonitor
    }
    

    
    /// Request accessibility permission with user prompt
    func requestAccessibilityPermission() {
        print("PermissionManager: Requesting accessibility permission...")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

        // Update status after a short delay to allow for user interaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updatePermissionStatus()
            print("PermissionManager: Permission status updated after request")
        }
    }

    /// Force open accessibility settings
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        print("PermissionManager: Opened accessibility settings")
    }


    

    
    /// Check if all required permissions are granted
    /// - Returns: True if all permissions are available
    func hasAllRequiredPermissions() -> Bool {
        return hasAccessibilityPermission
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
    

    
    /// Show permission prompt on first launch only
    func showFirstLaunchPermissionPrompt() {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: isFirstLaunchKey)

        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: isFirstLaunchKey)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showPermissionSetupAlert()
            }
        }

        print("PermissionManager: First launch permission prompt shown")
    }

    /// Show setup alert for permissions
    private func showPermissionSetupAlert() {
        let alert = NSAlert()
        alert.messageText = "欢迎使用 MouseQuicker"
        alert.informativeText = """
        为了正常使用，MouseQuicker 需要辅助功能权限来监听全局鼠标事件。

        请在系统偏好设置中手动授予此权限。
        如果应用无法正常工作，请检查权限设置。
        """
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "稍后设置")
        alert.alertStyle = .informational

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 打开辅助功能设置
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}


