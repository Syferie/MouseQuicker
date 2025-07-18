//
//  PieMenuController.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

/// Controller for managing pie menu display and interactions
class PieMenuController: NSObject, PieMenuControllerProtocol {
    
    // MARK: - Properties
    
    weak var delegate: PieMenuControllerDelegate?
    private(set) var isVisible: Bool = false
    
    // MARK: - Private Properties
    
    private var menuWindow: PieMenuWindow?
    private var currentMenuItems: [ShortcutItem] = []
    private let menuSize: CGFloat = 260.0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - PieMenuControllerProtocol Implementation
    
    func showMenu(at location: NSPoint, with items: [ShortcutItem]) {
        guard !isVisible else {
            // Update existing menu
            updateMenuItems(items)
            return
        }
        
        guard !items.isEmpty else {
            print("PieMenuController: Cannot show menu with no items")
            return
        }
        
        currentMenuItems = items
        
        // Create window if needed
        if menuWindow == nil {
            createMenuWindow()
        }
        
        guard let window = menuWindow else {
            print("PieMenuController: Failed to create menu window")
            return
        }
        
        // Configure menu
        window.menuView.delegate = self
        window.menuView.updateMenuItems(items)
        
        // Position and show window
        window.positionAt(location)
        
        // Notify delegate
        delegate?.pieMenuControllerWillShow(self)
        
        // Show with animation but DON'T make window key
        // This keeps MouseQuicker as background app while still showing the menu
        isVisible = true

        // Show window without making it key
        window.showAnimated {
            // Animation completed
        }
        
        print("PieMenuController: Showing menu at \(location) with \(items.count) items")
    }
    
    func hideMenu(animated: Bool) {
        guard isVisible, let window = menuWindow else { return }
        
        isVisible = false
        
        if animated {
            window.hideAnimated { [weak self] in
                self?.delegate?.pieMenuControllerDidHide(self!)
            }
        } else {
            window.orderOut(nil)
            delegate?.pieMenuControllerDidHide(self)
        }
        
        print("PieMenuController: Hiding menu")
    }
    
    func updateMenuItems(_ items: [ShortcutItem]) {
        currentMenuItems = items
        menuWindow?.menuView.updateMenuItems(items)
    }

    func updateMenuAppearance(_ appearance: MenuAppearance) {
        menuWindow?.menuView.updateAppearance(appearance)
        print("PieMenuController: Updated menu appearance - transparency: \(appearance.transparency), size: \(appearance.menuSize)")
    }
    
    // MARK: - Private Methods
    
    private func createMenuWindow() {
        // Create a full-screen window to capture all mouse events
        guard let screen = NSScreen.main else {
            print("PieMenuController: Could not get main screen")
            return
        }

        let windowRect = screen.frame
        menuWindow = PieMenuWindow(contentRect: windowRect)

        // Set up window delegate if needed
        // menuWindow?.delegate = self
    }
    
    private func executeShortcutItem(_ item: ShortcutItem) {
        print("PieMenuController: Executing shortcut item: \(item.title)")
        
        // Hide menu first
        hideMenu(animated: true)
        
        // Notify delegate
        delegate?.pieMenuController(self, didSelectItem: item)
    }
    
    // MARK: - Utility Methods
    
    /// Check if the menu is currently visible
    var menuIsVisible: Bool {
        return isVisible && menuWindow?.isVisible == true
    }
    
    /// Get current menu location
    var currentMenuLocation: NSPoint? {
        guard let window = menuWindow, isVisible else { return nil }
        let frame = window.frame
        return NSPoint(x: frame.midX, y: frame.midY)
    }
    
    /// Force hide menu without animation (for emergency cases)
    func forceHide() {
        isVisible = false
        menuWindow?.orderOut(nil)
        delegate?.pieMenuControllerDidHide(self)
    }

    /// 清理内存和资源
    func cleanup() {
        // 隐藏菜单
        forceHide()

        // 清理窗口
        menuWindow = nil

        print("PieMenuController: Cleanup completed")
    }
}

// MARK: - PieMenuViewDelegate

extension PieMenuController: PieMenuViewDelegate {
    func pieMenuView(_ view: PieMenuView, didClickSectorAt index: Int) {
        guard index >= 0 && index < currentMenuItems.count else {
            print("PieMenuController: Invalid sector index: \(index)")
            return
        }
        
        let item = currentMenuItems[index]
        executeShortcutItem(item)
    }
    
    func pieMenuView(_ view: PieMenuView, didHoverSectorAt index: Int) {
        // Could add hover feedback here if needed
        print("PieMenuController: Hovering over sector \(index)")
    }
    
    func pieMenuViewDidExitAllSectors(_ view: PieMenuView) {
        // Could add feedback when mouse exits all sectors
    }
    
    func pieMenuViewDidRequestDismissal(_ view: PieMenuView) {
        // User pressed ESC or requested dismissal
        hideMenu(animated: true)
        delegate?.pieMenuControllerDidCancel(self)
    }
}

// MARK: - NSWindowDelegate (if needed)

extension PieMenuController: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        // Hide menu when window loses focus
        if isVisible {
            hideMenu(animated: true)
            delegate?.pieMenuControllerDidCancel(self)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        if isVisible {
            isVisible = false
            delegate?.pieMenuControllerDidHide(self)
        }
    }
}

// MARK: - Debug and Testing

extension PieMenuController {
    /// Show a test menu with sample items
    func showTestMenu(at location: NSPoint) {
        let testItems = [
            ShortcutItem(title: "复制", shortcut: KeyboardShortcut(primaryKey: .c, modifiers: [.command]), iconName: "doc.on.doc", executionMode: .targetApp),
            ShortcutItem(title: "粘贴", shortcut: KeyboardShortcut(primaryKey: .v, modifiers: [.command]), iconName: "doc.on.clipboard", executionMode: .targetApp),
            ShortcutItem(title: "撤销", shortcut: KeyboardShortcut(primaryKey: .z, modifiers: [.command]), iconName: "arrow.uturn.backward", executionMode: .targetApp)
        ]
        
        showMenu(at: location, with: testItems)
    }
    
    /// Get debug information
    func getDebugInfo() -> [String: Any] {
        return [
            "isVisible": isVisible,
            "menuItemCount": currentMenuItems.count,
            "windowExists": menuWindow != nil,
            "windowVisible": menuWindow?.isVisible ?? false
        ]
    }
}
