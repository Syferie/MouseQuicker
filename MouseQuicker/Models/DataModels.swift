//
//  DataModels.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

// MARK: - KeyCode and ModifierKey Enums

/// Enumeration of supported key codes
enum KeyCode: String, Codable, CaseIterable {
    // Letters
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    
    // Numbers
    case digit0 = "0", digit1 = "1", digit2 = "2", digit3 = "3", digit4 = "4"
    case digit5 = "5", digit6 = "6", digit7 = "7", digit8 = "8", digit9 = "9"
    
    // Special keys
    case space, tab, enter, escape, delete, backspace
    case leftArrow, rightArrow, upArrow, downArrow
    case home, end, pageUp, pageDown
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    
    // Symbols
    case minus = "-", equal = "=", leftBracket = "[", rightBracket = "]"
    case backslash = "\\", semicolon = ";", quote = "'", comma = ","
    case period = ".", slash = "/", grave = "`"
    
    /// Display name for the key
    var displayName: String {
        switch self {
        case .digit0: return "0"
        case .digit1: return "1"
        case .digit2: return "2"
        case .digit3: return "3"
        case .digit4: return "4"
        case .digit5: return "5"
        case .digit6: return "6"
        case .digit7: return "7"
        case .digit8: return "8"
        case .digit9: return "9"
        case .space: return "Space"
        case .tab: return "Tab"
        case .enter: return "Enter"
        case .escape: return "Esc"
        case .delete: return "Delete"
        case .backspace: return "Backspace"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .upArrow: return "↑"
        case .downArrow: return "↓"
        case .home: return "Home"
        case .end: return "End"
        case .pageUp: return "Page Up"
        case .pageDown: return "Page Down"
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        default: return rawValue.uppercased()
        }
    }
}

/// Enumeration of modifier keys
enum ModifierKey: String, Codable, CaseIterable {
    case command = "cmd"
    case option = "opt"
    case control = "ctrl"
    case shift = "shift"
    case function = "fn"
    
    /// Display name for the modifier
    var displayName: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        case .function: return "fn"
        }
    }
    
    /// Full name for the modifier
    var fullName: String {
        switch self {
        case .command: return "Command"
        case .option: return "Option"
        case .control: return "Control"
        case .shift: return "Shift"
        case .function: return "Function"
        }
    }
}

// MARK: - KeyboardShortcut

/// Represents a keyboard shortcut with a primary key and modifiers
struct KeyboardShortcut: Codable, Hashable {
    let primaryKey: KeyCode
    let modifiers: Set<ModifierKey>
    
    init(primaryKey: KeyCode, modifiers: Set<ModifierKey> = []) {
        self.primaryKey = primaryKey
        self.modifiers = modifiers
    }
    
    /// Display string for the shortcut
    var displayString: String {
        let modifierStrings = modifiers.sorted { $0.rawValue < $1.rawValue }.map { $0.displayName }
        let keyString = primaryKey.displayName
        return (modifierStrings + [keyString]).joined(separator: "")
    }
    
    /// Full description of the shortcut
    var description: String {
        let modifierStrings = modifiers.sorted { $0.rawValue < $1.rawValue }.map { $0.fullName }
        let keyString = primaryKey.displayName
        return (modifierStrings + [keyString]).joined(separator: " + ")
    }
    
    /// Validate the shortcut
    var isValid: Bool {
        // At least one modifier is usually required for global shortcuts
        return !modifiers.isEmpty
    }
}

// MARK: - ShortcutExecutionMode

/// Defines how a shortcut should be executed
enum ShortcutExecutionMode: String, Codable, CaseIterable {
    case global = "global"           // 全局执行，发送到系统
    case targetApp = "targetApp"     // 应用内执行，发送到目标应用

    /// Display name for the execution mode
    var displayName: String {
        switch self {
        case .global: return "全局执行"
        case .targetApp: return "应用内执行"
        }
    }

    /// Description of the execution mode
    var description: String {
        switch self {
        case .global: return "快捷键将在系统级别触发，可以激活其他应用的功能"
        case .targetApp: return "快捷键将在当前应用内执行，适用于复制、粘贴等操作"
        }
    }

    /// Icon for the execution mode
    var icon: String {
        switch self {
        case .global: return "globe"
        case .targetApp: return "app.badge"
        }
    }
}

// MARK: - ApplicationScope

/// Defines the scope of applications where a shortcut should be active
enum ApplicationScopeMode: String, Codable, CaseIterable {
    case allApplications = "all"        // 在所有应用中生效
    case specificApplications = "specific"  // 仅在指定应用中生效
    case excludeApplications = "exclude"    // 在除指定应用外的所有应用中生效

    /// Display name for the scope mode
    var displayName: String {
        switch self {
        case .allApplications: return "所有应用"
        case .specificApplications: return "指定应用"
        case .excludeApplications: return "排除应用"
        }
    }

    /// Description of the scope mode
    var description: String {
        switch self {
        case .allApplications: return "快捷键在所有应用中都显示"
        case .specificApplications: return "快捷键仅在选定的应用中显示"
        case .excludeApplications: return "快捷键在除选定应用外的所有应用中显示"
        }
    }

    /// Icon for the scope mode
    var icon: String {
        switch self {
        case .allApplications: return "globe"
        case .specificApplications: return "app.badge.checkmark"
        case .excludeApplications: return "app.badge.minus"
        }
    }
}

/// Represents an application in the scope configuration
struct ApplicationInfo: Codable, Identifiable, Hashable {
    let id: String              // Bundle identifier
    let name: String            // Display name
    let bundlePath: String?     // Application bundle path

    init(id: String, name: String, bundlePath: String? = nil) {
        self.id = id
        self.name = name
        self.bundlePath = bundlePath
    }

    /// Create from NSRunningApplication
    init(from runningApp: NSRunningApplication) {
        self.id = runningApp.bundleIdentifier ?? "unknown.\(runningApp.processIdentifier)"
        self.name = runningApp.localizedName ?? "Unknown App"
        self.bundlePath = runningApp.bundleURL?.path
    }
}

/// Defines the application scope for a shortcut
struct ApplicationScope: Codable, Hashable {
    let mode: ApplicationScopeMode
    let applications: [ApplicationInfo]

    init(mode: ApplicationScopeMode = .allApplications, applications: [ApplicationInfo] = []) {
        self.mode = mode
        self.applications = applications
    }

    /// Check if the shortcut should be active for the given application
    func isActiveFor(application: NSRunningApplication) -> Bool {
        let appId = application.bundleIdentifier ?? "unknown.\(application.processIdentifier)"
        let containsApp = applications.contains { $0.id == appId }

        switch mode {
        case .allApplications:
            return true
        case .specificApplications:
            return containsApp
        case .excludeApplications:
            return !containsApp
        }
    }

    /// Get display text for the scope
    var displayText: String {
        switch mode {
        case .allApplications:
            return "所有应用"
        case .specificApplications:
            if applications.isEmpty {
                return "未选择应用"
            } else if applications.count == 1 {
                return applications.first!.name
            } else {
                return "\(applications.count)个应用"
            }
        case .excludeApplications:
            if applications.isEmpty {
                return "所有应用"
            } else if applications.count == 1 {
                return "除\(applications.first!.name)外"
            } else {
                return "除\(applications.count)个应用外"
            }
        }
    }

    /// Default scope (all applications)
    static let `default` = ApplicationScope()
}

// MARK: - ShortcutItem

/// Represents a single shortcut item in the pie menu
struct ShortcutItem: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let shortcut: KeyboardShortcut
    let iconName: String
    let isEnabled: Bool
    let executionMode: ShortcutExecutionMode  // 执行模式
    let applicationScope: ApplicationScope    // 新增：应用范围

    init(id: UUID = UUID(), title: String, shortcut: KeyboardShortcut, iconName: String, isEnabled: Bool = true, executionMode: ShortcutExecutionMode = .targetApp, applicationScope: ApplicationScope = .default) {
        self.id = id
        self.title = title
        self.shortcut = shortcut
        self.iconName = iconName
        self.isEnabled = isEnabled
        self.executionMode = executionMode
        self.applicationScope = applicationScope
    }

    /// Create a copy with modified properties
    func with(title: String? = nil, shortcut: KeyboardShortcut? = nil, iconName: String? = nil, isEnabled: Bool? = nil, executionMode: ShortcutExecutionMode? = nil, applicationScope: ApplicationScope? = nil) -> ShortcutItem {
        return ShortcutItem(
            id: self.id,
            title: title ?? self.title,
            shortcut: shortcut ?? self.shortcut,
            iconName: iconName ?? self.iconName,
            isEnabled: isEnabled ?? self.isEnabled,
            executionMode: executionMode ?? self.executionMode,
            applicationScope: applicationScope ?? self.applicationScope
        )
    }

    /// Check if this shortcut should be active for the given application
    func isActiveFor(application: NSRunningApplication) -> Bool {
        return isEnabled && applicationScope.isActiveFor(application: application)
    }
}

// MARK: - TriggerButton

/// Enumeration of supported trigger buttons
enum TriggerButton: String, Codable, CaseIterable {
    case left = "left"
    case middle = "middle"
    case right = "right"

    /// Display name for the trigger button
    var displayName: String {
        switch self {
        case .left: return "左键"
        case .middle: return "中键"
        case .right: return "右键"
        }
    }

    /// Description of the trigger button
    var description: String {
        switch self {
        case .left: return "使用鼠标左键长按触发菜单"
        case .middle: return "使用鼠标中键长按触发菜单"
        case .right: return "使用鼠标右键长按触发菜单"
        }
    }

    /// Icon for the trigger button
    var icon: String {
        switch self {
        case .left: return "cursorarrow.click"
        case .middle: return "cursorarrow.click.2"
        case .right: return "cursorarrow.click.badge.clock"
        }
    }

    /// Button number for NSEvent
    var buttonNumber: Int {
        switch self {
        case .left: return 0
        case .middle: return 2
        case .right: return 1
        }
    }

    /// NSEvent types for this button
    var eventTypes: (down: NSEvent.EventType, up: NSEvent.EventType, dragged: NSEvent.EventType) {
        switch self {
        case .left:
            return (.leftMouseDown, .leftMouseUp, .leftMouseDragged)
        case .middle:
            return (.otherMouseDown, .otherMouseUp, .otherMouseDragged)
        case .right:
            return (.rightMouseDown, .rightMouseUp, .rightMouseDragged)
        }
    }
}

// MARK: - MenuAppearance

/// Configuration for menu appearance
struct MenuAppearance: Codable {
    let transparency: Double
    let accentColor: String
    let menuSize: CGFloat

    init(transparency: Double = 0.7, accentColor: String = "systemBlue", menuSize: CGFloat = 200.0) {
        self.transparency = transparency
        self.accentColor = accentColor
        self.menuSize = menuSize
    }

    /// Default appearance
    static let `default` = MenuAppearance()
}

// MARK: - AppConfig

/// Main application configuration
struct AppConfig: Codable {
    let shortcutItems: [ShortcutItem]
    let triggerDuration: TimeInterval
    let triggerButton: TriggerButton
    let menuAppearance: MenuAppearance
    let version: String

    init(shortcutItems: [ShortcutItem] = [], triggerDuration: TimeInterval = 0.4, triggerButton: TriggerButton = .middle, menuAppearance: MenuAppearance = .default, version: String = "1.0") {
        self.shortcutItems = shortcutItems
        self.triggerDuration = triggerDuration
        self.triggerButton = triggerButton
        self.menuAppearance = menuAppearance
        self.version = version
    }

    /// Validate the configuration
    var isValid: Bool {
        return triggerDuration >= 0.1 && triggerDuration <= 1.0 && shortcutItems.count <= 20
    }

    /// Default configuration with sample shortcuts
    static let `default`: AppConfig = {
        let sampleShortcuts = [
            ShortcutItem(title: "复制", shortcut: KeyboardShortcut(primaryKey: .c, modifiers: [.command]), iconName: "doc.on.doc", executionMode: .targetApp, applicationScope: .default),
            ShortcutItem(title: "粘贴", shortcut: KeyboardShortcut(primaryKey: .v, modifiers: [.command]), iconName: "doc.on.clipboard", executionMode: .targetApp, applicationScope: .default),
            ShortcutItem(title: "撤销", shortcut: KeyboardShortcut(primaryKey: .z, modifiers: [.command]), iconName: "arrow.uturn.backward", executionMode: .targetApp, applicationScope: .default),
            ShortcutItem(title: "重做", shortcut: KeyboardShortcut(primaryKey: .z, modifiers: [.command, .shift]), iconName: "arrow.uturn.forward", executionMode: .targetApp, applicationScope: .default),
            ShortcutItem(title: "保存", shortcut: KeyboardShortcut(primaryKey: .s, modifiers: [.command]), iconName: "square.and.arrow.down", executionMode: .targetApp, applicationScope: .default)
        ]

        return AppConfig(shortcutItems: sampleShortcuts)
    }()
}
