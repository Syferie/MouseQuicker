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

        // Start permission monitoring
        PermissionManager.shared.startMonitoringPermissions()

        // Start the app coordinator
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
