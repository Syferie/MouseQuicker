//
//  PieMenuProtocols.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit



/// Delegate protocol for PieMenuController to handle menu interactions
protocol PieMenuControllerDelegate: AnyObject {
    /// Called when a shortcut item is selected from the pie menu
    /// - Parameters:
    ///   - controller: The PieMenuController instance
    ///   - item: The selected shortcut item
    func pieMenuController(_ controller: PieMenuController, didSelectItem item: ShortcutItem)
    
    /// Called when the pie menu is cancelled (ESC key or click outside)
    /// - Parameter controller: The PieMenuController instance
    func pieMenuControllerDidCancel(_ controller: PieMenuController)
    
    /// Called when the pie menu is about to appear
    /// - Parameter controller: The PieMenuController instance
    func pieMenuControllerWillShow(_ controller: PieMenuController)
    
    /// Called when the pie menu has been hidden
    /// - Parameter controller: The PieMenuController instance
    func pieMenuControllerDidHide(_ controller: PieMenuController)
}

/// Protocol defining the interface for pie menu control
protocol PieMenuControllerProtocol: AnyObject {
    /// Delegate to receive menu interaction notifications
    var delegate: PieMenuControllerDelegate? { get set }
    
    /// Whether the menu is currently visible
    var isVisible: Bool { get }
    
    /// Show the pie menu at the specified location
    /// - Parameters:
    ///   - location: Screen coordinates where to show the menu
    ///   - items: Array of shortcut items to display
    func showMenu(at location: NSPoint, with items: [ShortcutItem])
    
    /// Hide the pie menu
    /// - Parameter animated: Whether to animate the hiding
    func hideMenu(animated: Bool)
    
    /// Update the menu items while visible
    /// - Parameter items: New array of shortcut items
    func updateMenuItems(_ items: [ShortcutItem])
}

/// Delegate protocol for PieMenuView to handle user interactions
protocol PieMenuViewDelegate: AnyObject {
    /// Called when a menu sector is clicked
    /// - Parameters:
    ///   - view: The PieMenuView instance
    ///   - index: Index of the clicked sector
    func pieMenuView(_ view: PieMenuView, didClickSectorAt index: Int)
    
    /// Called when mouse enters a sector
    /// - Parameters:
    ///   - view: The PieMenuView instance
    ///   - index: Index of the hovered sector
    func pieMenuView(_ view: PieMenuView, didHoverSectorAt index: Int)
    
    /// Called when mouse exits all sectors
    /// - Parameter view: The PieMenuView instance
    func pieMenuViewDidExitAllSectors(_ view: PieMenuView)
    
    /// Called when the view requests to be dismissed (ESC key)
    /// - Parameter view: The PieMenuView instance
    func pieMenuViewDidRequestDismissal(_ view: PieMenuView)
}

/// Protocol defining the interface for pie menu view
protocol PieMenuViewProtocol: AnyObject {
    /// Delegate to receive user interaction notifications
    var delegate: PieMenuViewDelegate? { get set }
    
    /// Array of menu items to display
    var menuItems: [ShortcutItem] { get set }
    
    /// Index of currently hovered sector (-1 if none)
    var hoveredIndex: Int { get }
    
    /// Update the menu items and redraw
    /// - Parameter items: New array of shortcut items
    func updateMenuItems(_ items: [ShortcutItem])
    
    /// Animate the menu appearance
    /// - Parameter completion: Completion handler called when animation finishes
    func animateAppearance(completion: @escaping () -> Void)
    
    /// Animate the menu disappearance
    /// - Parameter completion: Completion handler called when animation finishes
    func animateDisappearance(completion: @escaping () -> Void)
    
    /// Calculate which sector contains the given point
    /// - Parameter point: Point in view coordinates
    /// - Returns: Index of the sector, or -1 if outside all sectors
    func sectorIndex(for point: NSPoint) -> Int
}
