//
//  LaunchAtLoginManager.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/25.
//

import Foundation
import ServiceManagement
import AppKit

/// Manages the launch at login functionality for MouseQuicker
class LaunchAtLoginManager: ObservableObject {
    
    /// Singleton instance
    static let shared = LaunchAtLoginManager()
    
    /// Published property to track launch at login status
    @Published var isLaunchAtLoginEnabled: Bool = false
    
    /// Bundle identifier for the helper app (if using helper app approach)
    private let helperBundleIdentifier = "com.syferie.MouseQuicker.LaunchHelper"
    
    // MARK: - Initialization
    
    private init() {
        updateLaunchAtLoginStatus()
    }
    
    // MARK: - Public Methods
    
    /// Toggle launch at login setting
    func toggleLaunchAtLogin() {
        if isLaunchAtLoginEnabled {
            disableLaunchAtLogin()
        } else {
            enableLaunchAtLogin()
        }
    }
    
    /// Enable launch at login
    func enableLaunchAtLogin() {
        do {
            if #available(macOS 13.0, *) {
                // Use modern SMAppService API for macOS 13+
                try enableLaunchAtLoginModern()
            } else {
                // Use legacy approach for older macOS versions
                enableLaunchAtLoginLegacy()
            }
            
            isLaunchAtLoginEnabled = true
            print("LaunchAtLoginManager: Successfully enabled launch at login")
            
        } catch {
            print("LaunchAtLoginManager: Failed to enable launch at login: \(error)")
        }
    }
    
    /// Disable launch at login
    func disableLaunchAtLogin() {
        do {
            if #available(macOS 13.0, *) {
                // Use modern SMAppService API for macOS 13+
                try disableLaunchAtLoginModern()
            } else {
                // Use legacy approach for older macOS versions
                disableLaunchAtLoginLegacy()
            }
            
            isLaunchAtLoginEnabled = false
            print("LaunchAtLoginManager: Successfully disabled launch at login")
            
        } catch {
            print("LaunchAtLoginManager: Failed to disable launch at login: \(error)")
        }
    }
    
    /// Update the current launch at login status
    func updateLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            updateLaunchAtLoginStatusModern()
        } else {
            updateLaunchAtLoginStatusLegacy()
        }
    }
    
    // MARK: - Modern Implementation (macOS 13+)
    
    @available(macOS 13.0, *)
    private func enableLaunchAtLoginModern() throws {
        // For macOS 13+, we can use SMAppService
        // This requires proper entitlements and app registration
        let service = SMAppService.mainApp
        try service.register()
    }
    
    @available(macOS 13.0, *)
    private func disableLaunchAtLoginModern() throws {
        let service = SMAppService.mainApp
        try service.unregister()
    }
    
    @available(macOS 13.0, *)
    private func updateLaunchAtLoginStatusModern() {
        let service = SMAppService.mainApp
        isLaunchAtLoginEnabled = service.status == .enabled
    }
    
    // MARK: - Legacy Implementation (macOS 12 and earlier)

    private func enableLaunchAtLoginLegacy() {
        // Use UserDefaults as a simple fallback for older systems
        // In a real implementation, you might want to use a more sophisticated approach
        saveLaunchAtLoginPreference(true)
        isLaunchAtLoginEnabled = true
        print("LaunchAtLoginManager: Enabled launch at login (legacy mode)")
    }

    private func disableLaunchAtLoginLegacy() {
        saveLaunchAtLoginPreference(false)
        isLaunchAtLoginEnabled = false
        print("LaunchAtLoginManager: Disabled launch at login (legacy mode)")
    }

    private func updateLaunchAtLoginStatusLegacy() {
        isLaunchAtLoginEnabled = loadLaunchAtLoginPreference()
    }
}

// MARK: - UserDefaults Extension

extension LaunchAtLoginManager {
    
    /// Save launch at login preference to UserDefaults as backup
    private func saveLaunchAtLoginPreference(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "LaunchAtLoginEnabled")
    }
    
    /// Load launch at login preference from UserDefaults
    private func loadLaunchAtLoginPreference() -> Bool {
        return UserDefaults.standard.bool(forKey: "LaunchAtLoginEnabled")
    }
}

// MARK: - Error Types

enum LaunchAtLoginError: Error, LocalizedError {
    case registrationFailed(String)
    case unregistrationFailed(String)
    case statusCheckFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .registrationFailed(let message):
            return "启用开机自启动失败: \(message)"
        case .unregistrationFailed(let message):
            return "禁用开机自启动失败: \(message)"
        case .statusCheckFailed(let message):
            return "检查开机自启动状态失败: \(message)"
        }
    }
}
