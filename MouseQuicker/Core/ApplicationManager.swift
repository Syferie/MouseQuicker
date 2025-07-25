//
//  ApplicationManager.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/25.
//

import Foundation
import AppKit

/// Manages application information and provides utilities for application scope configuration
class ApplicationManager: ObservableObject {
    
    /// Singleton instance
    static let shared = ApplicationManager()
    
    // MARK: - Published Properties
    
    @Published var runningApplications: [ApplicationInfo] = []
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 5.0 // 每5秒更新一次
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
        refreshRunningApplications()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Get all currently running applications
    func getAllRunningApplications() -> [ApplicationInfo] {
        let runningApps = NSWorkspace.shared.runningApplications
        
        return runningApps.compactMap { app in
            // 过滤掉系统进程和没有UI的应用
            guard app.activationPolicy == .regular,
                  let bundleId = app.bundleIdentifier,
                  !bundleId.isEmpty,
                  let name = app.localizedName,
                  !name.isEmpty else {
                return nil
            }
            
            return ApplicationInfo(from: app)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Search applications by name
    func searchApplications(query: String) -> [ApplicationInfo] {
        guard !query.isEmpty else {
            return runningApplications
        }
        
        return runningApplications.filter { app in
            app.name.localizedCaseInsensitiveContains(query) ||
            app.id.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Get application info by bundle identifier
    func getApplicationInfo(bundleId: String) -> ApplicationInfo? {
        return runningApplications.first { $0.id == bundleId }
    }
    
    /// Check if an application is currently running
    func isApplicationRunning(bundleId: String) -> Bool {
        return NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == bundleId
        }
    }
    
    /// Get the current frontmost application
    func getFrontmostApplication() -> ApplicationInfo? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontApp.bundleIdentifier else {
            return nil
        }
        
        return ApplicationInfo(from: frontApp)
    }
    
    /// Refresh the list of running applications
    func refreshRunningApplications() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let apps = self?.getAllRunningApplications() ?? []
            
            DispatchQueue.main.async {
                self?.runningApplications = apps
                self?.isLoading = false
            }
        }
    }
    
    /// Get commonly used applications (for quick selection)
    func getCommonApplications() -> [ApplicationInfo] {
        let commonBundleIds = [
            "com.apple.finder",
            "com.apple.Safari",
            "com.google.Chrome",
            "com.microsoft.VSCode",
            "com.apple.TextEdit",
            "com.apple.Terminal",
            "com.apple.mail",
            "com.apple.Notes",
            "com.apple.Preview",
            "com.apple.systempreferences"
        ]
        
        return runningApplications.filter { app in
            commonBundleIds.contains(app.id)
        }
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        // 监听应用启动和退出事件
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
        
        // 定时更新应用列表
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.refreshRunningApplications()
        }
    }
    
    private func stopMonitoring() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc private func applicationDidLaunch(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshRunningApplications()
        }
    }
    
    @objc private func applicationDidTerminate(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshRunningApplications()
        }
    }
}

// MARK: - Application Categories

extension ApplicationManager {
    
    /// Get applications grouped by category
    func getApplicationsByCategory() -> [String: [ApplicationInfo]] {
        var categories: [String: [ApplicationInfo]] = [:]
        
        for app in runningApplications {
            let category = getCategoryForApplication(app)
            if categories[category] == nil {
                categories[category] = []
            }
            categories[category]?.append(app)
        }
        
        return categories
    }
    
    private func getCategoryForApplication(_ app: ApplicationInfo) -> String {
        let bundleId = app.id.lowercased()
        
        if bundleId.contains("browser") || bundleId.contains("safari") || bundleId.contains("chrome") || bundleId.contains("firefox") {
            return "浏览器"
        } else if bundleId.contains("editor") || bundleId.contains("code") || bundleId.contains("xcode") {
            return "开发工具"
        } else if bundleId.contains("mail") || bundleId.contains("message") || bundleId.contains("slack") {
            return "通讯工具"
        } else if bundleId.contains("music") || bundleId.contains("video") || bundleId.contains("photo") {
            return "媒体工具"
        } else if bundleId.contains("apple") {
            return "系统应用"
        } else {
            return "其他应用"
        }
    }
}

// MARK: - Utility Extensions

extension ApplicationInfo {
    
    /// Get the application icon
    var icon: NSImage? {
        guard let bundlePath = bundlePath,
              let bundle = Bundle(path: bundlePath) else {
            return nil
        }
        
        return NSWorkspace.shared.icon(forFile: bundle.bundlePath)
    }
    
    /// Get a default icon if the app icon is not available
    var iconOrDefault: NSImage {
        return icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
    }
}
