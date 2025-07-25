//
//  MouseQuickerApp.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import SwiftUI
import AppKit

@main
struct MouseQuickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

/// Application delegate to handle app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the main window since this is a menu bar app
        NSApp.setActivationPolicy(.accessory)

        // Initialize launch at login manager
        _ = LaunchAtLoginManager.shared

        // Show permission prompt on first launch only
        PermissionManager.shared.showFirstLaunchPermissionPrompt()

        // Start the app coordinator (don't block on permissions)
        AppCoordinator.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppCoordinator.shared.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Don't reopen windows when clicking dock icon
        return false
    }
}
