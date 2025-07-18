//
//  AppCoordinator.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit
import SwiftUI



/// Main coordinator class that manages the application lifecycle and component interactions
class AppCoordinator: NSObject, ObservableObject, NSWindowDelegate {
    
    /// Singleton instance
    static let shared = AppCoordinator()
    
    // MARK: - Core Components
    private var eventMonitor: EventMonitor?
    private var pieMenuController: PieMenuController?
    private var shortcutExecutor: ShortcutExecutor?
    private var configManager: ConfigManager
    
    // MARK: - State
    @Published var isRunning = false
    @Published var currentConfig: AppConfig?
    
    // MARK: - Menu Bar
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    // MARK: - Target Application Tracking
    private var targetApplication: NSRunningApplication?

    // MARK: - Memory Management
    private var memoryCleanupTimer: Timer?
    
    private override init() {
        // Initialize config manager first
        configManager = ConfigManager.shared
        super.init()
        setupComponents()
        setupMenuBar()
    }
    
    // MARK: - Lifecycle
    
    /// Start the application
    func start() {
        guard !isRunning else { return }
        
        // Check permissions first
        guard PermissionManager.shared.hasAllRequiredPermissions() else {
            handleMissingPermissions()
            return
        }
        
        do {
            // Load configuration
            currentConfig = configManager.loadConfiguration()

            // Start event monitoring
            try eventMonitor?.startMonitoring()

            isRunning = true

            // 启动内存清理定时器
            startMemoryCleanupTimer()

            print("MouseQuicker started successfully")

        } catch {
            print("Failed to start MouseQuicker: \(error)")
            ErrorHandler.shared.handleError(error, context: "应用启动", showAlert: true)
        }
    }
    
    /// Stop the application
    func stop() {
        guard isRunning else { return }
        
        eventMonitor?.stopMonitoring()
        pieMenuController?.hideMenu(animated: false)

        // 停止内存清理定时器
        stopMemoryCleanupTimer()

        isRunning = false
        print("MouseQuicker stopped")
    }
    
    /// Restart the application
    func restart() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.start()
        }
    }
    
    // MARK: - Configuration
    
    /// Update the application configuration
    /// - Parameter config: New configuration to apply
    func updateConfiguration(_ config: AppConfig) {
        do {
            try configManager.saveConfiguration(config)
            currentConfig = config

            // Apply configuration changes
            applyConfiguration(config)

            print("Configuration updated successfully")

        } catch {
            print("Failed to update configuration: \(error)")
            ErrorHandler.shared.handleError(error, context: "配置更新", showAlert: false)
        }
    }
    
    /// Apply configuration to running components
    /// - Parameter config: Configuration to apply
    private func applyConfiguration(_ config: AppConfig) {
        // Update trigger duration
        eventMonitor?.updateTriggerDuration(config.triggerDuration)
        
        // Update menu items in pie menu controller
        pieMenuController?.updateMenuItems(config.shortcutItems)
    }
    
    // MARK: - Private Setup
    
    private func setupComponents() {
        // Initialize components
        eventMonitor = EventMonitor()
        pieMenuController = PieMenuController()
        shortcutExecutor = ShortcutExecutor()

        // Set up delegates
        eventMonitor?.delegate = self
        pieMenuController?.delegate = self

        // Set up configuration change notifications
        setupConfigurationNotifications()

        print("AppCoordinator: Components initialized")
    }

    private func setupConfigurationNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configurationDidChange(_:)),
            name: .configurationDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configurationDidImport(_:)),
            name: .configurationDidImport,
            object: nil
        )

        print("AppCoordinator: Configuration notifications set up")
    }

    @objc private func configurationDidChange(_ notification: Notification) {
        guard let config = notification.object as? AppConfig else { return }

        print("AppCoordinator: Configuration changed, updating components")
        currentConfig = config
        applyConfiguration(config)
    }

    @objc private func configurationDidImport(_ notification: Notification) {
        guard let config = notification.object as? AppConfig else { return }

        print("AppCoordinator: Configuration imported, updating components")
        currentConfig = config
        applyConfiguration(config)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.grid.3x3", accessibilityDescription: "MouseQuicker")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        
        setupStatusMenu()
    }
    
    private func setupStatusMenu() {
        let menu = NSMenu()

        // Settings menu item
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Start/Stop menu item
        let startStopItem = NSMenuItem(
            title: isRunning ? "停止" : "启动",
            action: #selector(toggleRunning),
            keyEquivalent: ""
        )
        startStopItem.target = self
        menu.addItem(startStopItem)

        // Test menu item
        let testItem = NSMenuItem(title: "测试菜单", action: #selector(testPieMenu), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)

        menu.addItem(NSMenuItem.separator())

        // Quit menu item
        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }
    
    // MARK: - Menu Actions
    
    @objc private func statusItemClicked() {
        // Update menu state
        setupStatusMenu()
    }
    
    @objc private func openSettings() {
        print("Opening settings window...")

        // Force app to become active first
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Create or show settings window
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )

            settingsWindow?.title = "MouseQuicker 设置"
            settingsWindow?.contentViewController = hostingController
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false  // 手动管理窗口生命周期
            settingsWindow?.level = .floating

            // Set window delegate to handle close
            settingsWindow?.delegate = self
        }

        // Show and activate window
        settingsWindow?.makeKeyAndOrderFront(self)
        settingsWindow?.orderFrontRegardless()

        // Ensure window is key and main
        DispatchQueue.main.async { [weak self] in
            self?.settingsWindow?.makeKey()
            self?.settingsWindow?.makeMain()
        }
    }
    
    @objc private func toggleRunning() {
        if isRunning {
            stop()
        } else {
            start()
        }
        setupStatusMenu()
    }
    
    @objc private func quit() {
        stop()
        cleanupMemory()
        NSApplication.shared.terminate(nil)
    }

    /// 清理内存，释放缓存
    private func cleanupMemory() {
        // 清理图标缓存
        IconManager.shared.clearCache()

        // 清理性能监控数据
        PerformanceMonitor.shared.cleanupOldMetrics()

        // 清理菜单控制器
        pieMenuController?.cleanup()

        print("AppCoordinator: Memory cleanup completed")
    }

    /// 启动定期内存清理
    private func startMemoryCleanupTimer() {
        // 每5分钟清理一次内存
        memoryCleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.performPeriodicCleanup()
        }
    }

    /// 停止定期内存清理
    private func stopMemoryCleanupTimer() {
        memoryCleanupTimer?.invalidate()
        memoryCleanupTimer = nil
    }

    /// 执行定期清理
    private func performPeriodicCleanup() {
        // 在后台线程执行清理，避免阻塞主线程
        DispatchQueue.global(qos: .utility).async {
            // 只清理性能监控数据，不再基于内存使用进行清理
            PerformanceMonitor.shared.cleanupOldMetrics()

            print("AppCoordinator: Periodic cleanup completed")
        }
    }



    /// Test the pie menu functionality
    @objc private func testPieMenu() {
        guard let config = currentConfig else { return }
        let mouseLocation = NSEvent.mouseLocation
        pieMenuController?.showMenu(at: mouseLocation, with: config.shortcutItems)
    }
    
    // MARK: - Error Handling

    private func handleMissingPermissions() {
        if !PermissionManager.shared.hasAccessibilityPermission {
            PermissionManager.shared.handleMissingAccessibilityPermission()
        }

        if !PermissionManager.shared.hasInputMonitoringPermission {
            PermissionManager.shared.handleMissingInputMonitoringPermission()
        }
    }

    private func handleStartupError(_ error: Error) {
        // This is now handled by ErrorHandler.shared.handleError
        // Keep this method for backward compatibility if needed
    }

    // MARK: - Memory Management

    deinit {
        // Clean up resources
        NotificationCenter.default.removeObserver(self)
        print("AppCoordinator: Deinitialized")
    }
}

// MARK: - EventMonitorDelegate (will be implemented when EventMonitor is ready)
extension AppCoordinator: EventMonitorDelegate {
    func eventMonitor(_ monitor: EventMonitor, didDetectTriggerAt location: NSPoint) {
        guard let config = currentConfig else { return }
        pieMenuController?.showMenu(at: location, with: config.shortcutItems)
    }
    
    func eventMonitor(_ monitor: EventMonitor, didCancelTrigger: Void) {
        // Handle trigger cancellation if needed
    }
}

// MARK: - PieMenuControllerDelegate (will be implemented when PieMenuController is ready)
extension AppCoordinator: PieMenuControllerDelegate {
    func pieMenuController(_ controller: PieMenuController, didSelectItem item: ShortcutItem) {
        // Execute shortcut in the context of the target application
        if let targetApp = targetApplication {
            let _ = shortcutExecutor?.executeShortcutItem(item, targetApplication: targetApp)
        } else {
            let _ = shortcutExecutor?.executeShortcutItem(item)
        }
    }
    
    func pieMenuControllerDidCancel(_ controller: PieMenuController) {
        // Handle menu cancellation if needed
    }
    
    func pieMenuControllerWillShow(_ controller: PieMenuController) {
        // Remember the currently active application before showing menu
        targetApplication = NSWorkspace.shared.frontmostApplication
        print("AppCoordinator: Remembered target application: \(targetApplication?.localizedName ?? "Unknown")")
    }
    
    func pieMenuControllerDidHide(_ controller: PieMenuController) {
        // Handle menu did hide if needed
    }
}

// MARK: - NSWindowDelegate

extension AppCoordinator {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == settingsWindow {
            print("Settings window will close")
            settingsWindow = nil
            // Return to accessory mode when settings window closes
            NSApp.setActivationPolicy(.accessory)
            print("Settings window closed")
        }
    }



    func windowDidBecomeKey(_ notification: Notification) {
        if notification.object as? NSWindow == settingsWindow {
            print("Settings window became key")
        }
    }
}
