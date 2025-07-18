//
//  DataModels.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation

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

// MARK: - ShortcutItem

/// Represents a single shortcut item in the pie menu
struct ShortcutItem: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let shortcut: KeyboardShortcut
    let iconName: String
    let isEnabled: Bool
    
    init(id: UUID = UUID(), title: String, shortcut: KeyboardShortcut, iconName: String, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.shortcut = shortcut
        self.iconName = iconName
        self.isEnabled = isEnabled
    }
    
    /// Create a copy with modified properties
    func with(title: String? = nil, shortcut: KeyboardShortcut? = nil, iconName: String? = nil, isEnabled: Bool? = nil) -> ShortcutItem {
        return ShortcutItem(
            id: self.id,
            title: title ?? self.title,
            shortcut: shortcut ?? self.shortcut,
            iconName: iconName ?? self.iconName,
            isEnabled: isEnabled ?? self.isEnabled
        )
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
    let menuAppearance: MenuAppearance
    let version: String
    
    init(shortcutItems: [ShortcutItem] = [], triggerDuration: TimeInterval = 0.4, menuAppearance: MenuAppearance = .default, version: String = "1.0") {
        self.shortcutItems = shortcutItems
        self.triggerDuration = triggerDuration
        self.menuAppearance = menuAppearance
        self.version = version
    }
    
    /// Validate the configuration
    var isValid: Bool {
        return triggerDuration >= 0.1 && triggerDuration <= 1.0 && shortcutItems.count <= 10
    }
    
    /// Default configuration with sample shortcuts
    static let `default`: AppConfig = {
        let sampleShortcuts = [
            ShortcutItem(title: "复制", shortcut: KeyboardShortcut(primaryKey: .c, modifiers: [.command]), iconName: "doc.on.doc"),
            ShortcutItem(title: "粘贴", shortcut: KeyboardShortcut(primaryKey: .v, modifiers: [.command]), iconName: "doc.on.clipboard"),
            ShortcutItem(title: "撤销", shortcut: KeyboardShortcut(primaryKey: .z, modifiers: [.command]), iconName: "arrow.uturn.backward"),
            ShortcutItem(title: "重做", shortcut: KeyboardShortcut(primaryKey: .z, modifiers: [.command, .shift]), iconName: "arrow.uturn.forward"),
            ShortcutItem(title: "保存", shortcut: KeyboardShortcut(primaryKey: .s, modifiers: [.command]), iconName: "square.and.arrow.down")
        ]
        
        return AppConfig(shortcutItems: sampleShortcuts)
    }()
}
