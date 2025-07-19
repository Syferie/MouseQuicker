//
//  PermissionManager.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

// MARK: - Global Permission Check Functions

/// Check if the process is trusted for accessibility
/// - Parameter prompt: Whether to show the permission prompt
/// - Returns: True if the process is trusted
func checkIsProcessTrusted(prompt: Bool = false) -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

/// Manager for handling system permissions required by the application
class PermissionManager: ObservableObject {
    
    /// Singleton instance
    static let shared = PermissionManager()
    
    /// Published properties for SwiftUI binding (for display only)
    @Published var hasAccessibilityPermission = false

    /// Track if this is the first launch
    private let isFirstLaunchKey = "MouseQuicker_FirstLaunch"

    /// Cache for permission check results to avoid frequent system calls
    private var cachedPermissionResult: Bool?
    private var lastPermissionCheck: Date?
    private let permissionCacheTimeout: TimeInterval = 5.0 // Cache for 5 seconds

    private init() {
        // Don't check permissions automatically
    }

    /// Check and update the current permission status (manual only)
    func updatePermissionStatus() {
        hasAccessibilityPermission = checkAccessibilityPermission(useCache: false) // Force fresh check
        print("PermissionManager: 权限状态已更新 - 辅助功能权限: \(hasAccessibilityPermission)")
    }

    /// Clear the permission cache to force a fresh check next time
    func clearPermissionCache() {
        cachedPermissionResult = nil
        lastPermissionCheck = nil
        print("PermissionManager: Permission cache cleared")
    }
    
    /// Check if accessibility permission is granted
    /// - Parameter useCache: Whether to use cached result if available
    /// - Returns: True if permission is granted
    func checkAccessibilityPermission(useCache: Bool = true) -> Bool {
        // Check cache first if enabled
        if useCache, let cachedResult = cachedPermissionResult,
           let lastCheck = lastPermissionCheck,
           Date().timeIntervalSince(lastCheck) < permissionCacheTimeout {
            print("PermissionManager: Using cached permission result: \(cachedResult)")
            return cachedResult
        }

        // Use the global function for consistency with Ice project
        let isGranted = checkIsProcessTrusted(prompt: false)

        print("PermissionManager: Accessibility permission check result: \(isGranted)")
        print("PermissionManager: Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

        // Only use secondary check if the primary check fails AND we're in debug mode
        // This reduces false positives in production
        var finalResult = isGranted
        #if DEBUG
        if !isGranted {
            let secondaryCheck = testGlobalEventMonitor()
            print("PermissionManager: Secondary check result: \(secondaryCheck)")
            // In debug mode, be more conservative - only return true if both checks pass
            finalResult = secondaryCheck && isGranted
        }
        #endif

        // Cache the result
        cachedPermissionResult = finalResult
        lastPermissionCheck = Date()

        return finalResult
    }

    /// Test if we can create a global event monitor (secondary permission check)
    /// This is a more conservative check that only returns true if we can actually monitor events
    private func testGlobalEventMonitor() -> Bool {
        var canCreateMonitor = false
        var receivedEvent = false

        // Use a very short timeout to avoid blocking
        let semaphore = DispatchSemaphore(value: 0)

        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
            receivedEvent = true
            semaphore.signal()
        }

        if let monitor = monitor {
            canCreateMonitor = true

            // Wait briefly to see if we can actually receive events
            let result = semaphore.wait(timeout: .now() + 0.1)

            NSEvent.removeMonitor(monitor)

            // Only consider it successful if we could both create the monitor AND receive events
            let success = canCreateMonitor && (result == .success || receivedEvent)
            print("PermissionManager: Test monitor - created: \(canCreateMonitor), received events: \(receivedEvent), success: \(success)")
            return success
        } else {
            print("PermissionManager: Failed to create test monitor")
            return false
        }
    }
    

    
    /// Request accessibility permission with user prompt
    func requestAccessibilityPermission() {
        print("PermissionManager: Requesting accessibility permission...")

        // Clear cache before requesting to ensure fresh check
        clearPermissionCache()

        let _ = checkIsProcessTrusted(prompt: true)

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


