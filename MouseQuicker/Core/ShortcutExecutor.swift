//
//  ShortcutExecutor.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit
import Carbon

/// Implementation of keyboard shortcut execution
class ShortcutExecutor: ShortcutExecutorProtocol {
    
    // MARK: - Properties
    
    private let eventSource: CGEventSource
    
    // MARK: - Initialization
    
    init() {
        // Create event source for generating keyboard events
        eventSource = CGEventSource(stateID: .hidSystemState) ?? CGEventSource(stateID: .combinedSessionState)!
    }
    
    // MARK: - ShortcutExecutorProtocol Implementation
    
    func execute(_ shortcut: KeyboardShortcut) -> Bool {
        guard canExecute(shortcut) else {
            print("ShortcutExecutor: Cannot execute shortcut - validation failed")
            return false
        }

        let startTime = Date()

        do {
            try executeShortcutInternal(shortcut)
            let executionTime = Date().timeIntervalSince(startTime)
            print("ShortcutExecutor: Successfully executed \(shortcut.displayString) in \(executionTime)s")
            return true
        } catch {
            print("ShortcutExecutor: Failed to execute shortcut: \(error)")
            return false
        }
    }

    func execute(_ shortcut: KeyboardShortcut, targetApplication: NSRunningApplication) -> Bool {
        guard canExecute(shortcut) else {
            print("ShortcutExecutor: Cannot execute shortcut \(shortcut.displayString)")
            return false
        }

        let startTime = Date()

        do {
            try executeShortcutInternal(shortcut, targetApplication: targetApplication)
            let executionTime = Date().timeIntervalSince(startTime)
            print("ShortcutExecutor: Successfully executed \(shortcut.displayString) for \(targetApplication.localizedName ?? "Unknown") in \(executionTime)s")
            return true
        } catch {
            print("ShortcutExecutor: Failed to execute shortcut: \(error)")
            return false
        }
    }
    
    func canExecute(_ shortcut: KeyboardShortcut) -> Bool {
        // Check if shortcut is valid
        guard shortcut.isValid else { return false }
        
        // Check if we can map the key code
        guard let _ = mapKeyCodeToCGKeyCode(shortcut.primaryKey) else { return false }
        
        // Check if all modifiers are supported
        for modifier in shortcut.modifiers {
            guard mapModifierToCGEventFlags(modifier) != [] else { return false }
        }
        
        return true
    }
    
    func executeShortcutItem(_ item: ShortcutItem) -> Bool {
        guard item.isEnabled else {
            print("ShortcutExecutor: Shortcut item '\(item.title)' is disabled")
            return false
        }

        print("ShortcutExecutor: Executing shortcut item '\(item.title)': \(item.shortcut.displayString) in \(item.executionMode.displayName) mode")

        // 根据执行模式决定如何执行
        switch item.executionMode {
        case .global:
            return execute(item.shortcut)  // 全局执行
        case .targetApp:
            return execute(item.shortcut)  // 应用内执行（无目标应用时的默认行为）
        }
    }

    func executeShortcutItem(_ item: ShortcutItem, targetApplication: NSRunningApplication) -> Bool {
        guard item.isEnabled else {
            print("ShortcutExecutor: Shortcut item '\(item.title)' is disabled")
            return false
        }

        print("ShortcutExecutor: Executing shortcut item '\(item.title)': \(item.shortcut.displayString) in \(item.executionMode.displayName) mode for app: \(targetApplication.localizedName ?? "Unknown")")

        // 根据执行模式决定如何执行
        switch item.executionMode {
        case .global:
            return execute(item.shortcut)  // 全局执行，忽略目标应用
        case .targetApp:
            return execute(item.shortcut, targetApplication: targetApplication)  // 应用内执行
        }
    }
    
    // MARK: - Private Implementation
    
    private func executeShortcutInternal(_ shortcut: KeyboardShortcut) throws {
        try executeShortcutInternal(shortcut, targetApplication: nil)
    }

    private func executeShortcutInternal(_ shortcut: KeyboardShortcut, targetApplication: NSRunningApplication?) throws {
        guard let keyCode = mapKeyCodeToCGKeyCode(shortcut.primaryKey) else {
            throw ShortcutExecutionError.invalidShortcut
        }

        // Build modifier flags
        var flags: CGEventFlags = []
        for modifier in shortcut.modifiers {
            flags.formUnion(mapModifierToCGEventFlags(modifier))
        }

        // Create key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: true) else {
            throw ShortcutExecutionError.systemEventCreationFailed
        }

        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: false) else {
            throw ShortcutExecutionError.systemEventCreationFailed
        }

        // Set modifier flags
        keyDownEvent.flags = flags
        keyUpEvent.flags = flags

        if let targetApp = targetApplication {
            // HUD 模式下的精确快捷键执行
            // 由于我们使用了真正的无焦点浮层，目标应用应该仍然保持焦点
            print("ShortcutExecutor: Sending shortcut to target app: \(targetApp.localizedName ?? "Unknown") (PID: \(targetApp.processIdentifier))")

            // 检查目标应用是否仍然是前台应用
            let currentFrontApp = NSWorkspace.shared.frontmostApplication
            if currentFrontApp?.processIdentifier != targetApp.processIdentifier {
                // 如果目标应用不再是前台应用，说明用户可能切换了应用
                // 在 HUD 模式下，这种情况应该很少发生
                print("ShortcutExecutor: Target app is no longer frontmost, activating it")
                if #available(macOS 14.0, *) {
                    targetApp.activate()
                } else {
                    targetApp.activate(options: [.activateIgnoringOtherApps])
                }
                // 等待应用激活
                usleep(50000) // 50ms delay
            } else {
                // 目标应用仍然是前台应用 - 这是 HUD 模式的预期行为
                // 使用最小延迟以保持响应性
                usleep(5000) // 5ms delay
                print("ShortcutExecutor: Target app maintained focus (HUD mode working correctly)")
            }

            // 直接发送事件到目标应用
            keyDownEvent.postToPid(targetApp.processIdentifier)
            usleep(1000) // 1ms delay between key down and up
            keyUpEvent.postToPid(targetApp.processIdentifier)

        } else {
            // 没有目标应用时，发送到系统
            print("ShortcutExecutor: No target app, sending to system")
            keyDownEvent.post(tap: .cghidEventTap)
            usleep(1000) // 1ms delay
            keyUpEvent.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - Key Mapping
    
    private func mapKeyCodeToCGKeyCode(_ keyCode: KeyCode) -> CGKeyCode? {
        switch keyCode {
        // Letters
        case .a: return CGKeyCode(kVK_ANSI_A)
        case .b: return CGKeyCode(kVK_ANSI_B)
        case .c: return CGKeyCode(kVK_ANSI_C)
        case .d: return CGKeyCode(kVK_ANSI_D)
        case .e: return CGKeyCode(kVK_ANSI_E)
        case .f: return CGKeyCode(kVK_ANSI_F)
        case .g: return CGKeyCode(kVK_ANSI_G)
        case .h: return CGKeyCode(kVK_ANSI_H)
        case .i: return CGKeyCode(kVK_ANSI_I)
        case .j: return CGKeyCode(kVK_ANSI_J)
        case .k: return CGKeyCode(kVK_ANSI_K)
        case .l: return CGKeyCode(kVK_ANSI_L)
        case .m: return CGKeyCode(kVK_ANSI_M)
        case .n: return CGKeyCode(kVK_ANSI_N)
        case .o: return CGKeyCode(kVK_ANSI_O)
        case .p: return CGKeyCode(kVK_ANSI_P)
        case .q: return CGKeyCode(kVK_ANSI_Q)
        case .r: return CGKeyCode(kVK_ANSI_R)
        case .s: return CGKeyCode(kVK_ANSI_S)
        case .t: return CGKeyCode(kVK_ANSI_T)
        case .u: return CGKeyCode(kVK_ANSI_U)
        case .v: return CGKeyCode(kVK_ANSI_V)
        case .w: return CGKeyCode(kVK_ANSI_W)
        case .x: return CGKeyCode(kVK_ANSI_X)
        case .y: return CGKeyCode(kVK_ANSI_Y)
        case .z: return CGKeyCode(kVK_ANSI_Z)
        
        // Numbers
        case .digit0: return CGKeyCode(kVK_ANSI_0)
        case .digit1: return CGKeyCode(kVK_ANSI_1)
        case .digit2: return CGKeyCode(kVK_ANSI_2)
        case .digit3: return CGKeyCode(kVK_ANSI_3)
        case .digit4: return CGKeyCode(kVK_ANSI_4)
        case .digit5: return CGKeyCode(kVK_ANSI_5)
        case .digit6: return CGKeyCode(kVK_ANSI_6)
        case .digit7: return CGKeyCode(kVK_ANSI_7)
        case .digit8: return CGKeyCode(kVK_ANSI_8)
        case .digit9: return CGKeyCode(kVK_ANSI_9)
        
        // Special keys
        case .space: return CGKeyCode(kVK_Space)
        case .tab: return CGKeyCode(kVK_Tab)
        case .enter: return CGKeyCode(kVK_Return)
        case .escape: return CGKeyCode(kVK_Escape)
        case .delete: return CGKeyCode(kVK_ForwardDelete)
        case .backspace: return CGKeyCode(kVK_Delete)
        
        // Arrow keys
        case .leftArrow: return CGKeyCode(kVK_LeftArrow)
        case .rightArrow: return CGKeyCode(kVK_RightArrow)
        case .upArrow: return CGKeyCode(kVK_UpArrow)
        case .downArrow: return CGKeyCode(kVK_DownArrow)
        
        // Navigation keys
        case .home: return CGKeyCode(kVK_Home)
        case .end: return CGKeyCode(kVK_End)
        case .pageUp: return CGKeyCode(kVK_PageUp)
        case .pageDown: return CGKeyCode(kVK_PageDown)
        
        // Function keys
        case .f1: return CGKeyCode(kVK_F1)
        case .f2: return CGKeyCode(kVK_F2)
        case .f3: return CGKeyCode(kVK_F3)
        case .f4: return CGKeyCode(kVK_F4)
        case .f5: return CGKeyCode(kVK_F5)
        case .f6: return CGKeyCode(kVK_F6)
        case .f7: return CGKeyCode(kVK_F7)
        case .f8: return CGKeyCode(kVK_F8)
        case .f9: return CGKeyCode(kVK_F9)
        case .f10: return CGKeyCode(kVK_F10)
        case .f11: return CGKeyCode(kVK_F11)
        case .f12: return CGKeyCode(kVK_F12)
        
        // Symbols
        case .minus: return CGKeyCode(kVK_ANSI_Minus)
        case .equal: return CGKeyCode(kVK_ANSI_Equal)
        case .leftBracket: return CGKeyCode(kVK_ANSI_LeftBracket)
        case .rightBracket: return CGKeyCode(kVK_ANSI_RightBracket)
        case .backslash: return CGKeyCode(kVK_ANSI_Backslash)
        case .semicolon: return CGKeyCode(kVK_ANSI_Semicolon)
        case .quote: return CGKeyCode(kVK_ANSI_Quote)
        case .comma: return CGKeyCode(kVK_ANSI_Comma)
        case .period: return CGKeyCode(kVK_ANSI_Period)
        case .slash: return CGKeyCode(kVK_ANSI_Slash)
        case .grave: return CGKeyCode(kVK_ANSI_Grave)
        }
    }
    
    private func mapModifierToCGEventFlags(_ modifier: ModifierKey) -> CGEventFlags {
        switch modifier {
        case .command: return .maskCommand
        case .option: return .maskAlternate
        case .control: return .maskControl
        case .shift: return .maskShift
        case .function: return .maskSecondaryFn
        }
    }
    
    // MARK: - Utility Methods
    
    /// Test if shortcut execution is working
    func testExecution() -> Bool {
        // Test with a simple, safe shortcut (Cmd+Space which opens Spotlight)
        let testShortcut = KeyboardShortcut(primaryKey: .space, modifiers: [.command])
        return canExecute(testShortcut)
    }
    
    /// Get execution statistics
    func getExecutionStats() -> (successful: Int, failed: Int) {
        // This would be implemented with actual tracking in a real app
        return (successful: 0, failed: 0)
    }
}
