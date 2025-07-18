//
//  PieMenuWindow.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

/// Custom window for displaying the pie menu
class PieMenuWindow: NSWindow {
    
    // MARK: - Properties
    
    private let pieMenuView: PieMenuView
    
    // MARK: - Initialization
    
    init(contentRect: NSRect) {
        // Create the pie menu view with initial size (will be repositioned later)
        let initialMenuFrame = NSRect(x: 0, y: 0, width: 260, height: 260)
        pieMenuView = PieMenuView(frame: initialMenuFrame)

        // Initialize window with special properties (now full-screen)
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupContentView()
    }
    
    private func setupWindow() {
        // Window properties for overlay display
        level = .floating
        isOpaque = false
        backgroundColor = NSColor.clear
        hasShadow = true
        ignoresMouseEvents = false

        // Make window appear above all other windows
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Enable mouse events but don't steal focus
        acceptsMouseMovedEvents = true

        // Don't release when closed and don't become key
        isReleasedWhenClosed = false
    }
    
    private func setupContentView() {
        // Create a container view that fills the entire window
        let containerView = FullScreenEventView(frame: frame)
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        containerView.pieMenuView = pieMenuView

        // Add the pie menu view to the container
        containerView.addSubview(pieMenuView)

        // Set the container as the content view
        contentView = containerView
    }
    
    // MARK: - Public Interface
    
    /// Get the pie menu view
    var menuView: PieMenuView {
        return pieMenuView
    }
    
    /// Position the window at the specified screen location
    func positionAt(_ location: NSPoint) {
        // Window is now full-screen, so we need to position the pie menu view within it
        // Convert the location to window coordinates and center the pie menu view there
        let menuSize: CGFloat = 220.0
        let menuFrame = NSRect(
            x: location.x - menuSize / 2,
            y: location.y - menuSize / 2,
            width: menuSize,
            height: menuSize
        )

        // Update the pie menu view frame
        pieMenuView.frame = menuFrame

        print("PieMenuWindow: Positioned menu at \(location), menuFrame=\(menuFrame)")
    }
    
    /// Show the window with animation
    func showAnimated(completion: @escaping () -> Void = {}) {
        // 确保菜单视图处于隐藏状态
        pieMenuView.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1.0)
        pieMenuView.layer?.opacity = 0.0

        // Only order front if not already visible
        if !isVisible {
            orderFront(nil)
        }

        // 立即开始动画
        pieMenuView.animateAppearance(completion: completion)
    }
    
    /// Hide the window with animation
    func hideAnimated(completion: @escaping () -> Void = {}) {
        pieMenuView.animateDisappearance { [weak self] in
            self?.orderOut(nil)
            completion()
        }
    }
    
    // MARK: - Window Events

    override var canBecomeKey: Bool {
        // Don't become key window to avoid interfering with target application focus
        return false
    }

    // MARK: - Memory Management

    deinit {
        // 清理菜单视图缓存
        pieMenuView.clearCache()
    }
}

/// A full-screen view that captures all mouse events and forwards them appropriately
private class FullScreenEventView: NSView {
    weak var pieMenuView: PieMenuView?

    override func mouseDown(with event: NSEvent) {
        print("FullScreenEventView: mouseDown at \(event.locationInWindow)")

        guard let pieMenuView = pieMenuView else {
            print("FullScreenEventView: No pie menu view, ignoring event")
            return
        }

        // Check if the click is within the pie menu view's frame
        let windowPoint = event.locationInWindow
        let pieMenuFrame = pieMenuView.frame

        if pieMenuFrame.contains(windowPoint) {
            // Forward the event to the pie menu view
            print("FullScreenEventView: Forwarding event to pie menu view")
            pieMenuView.mouseDown(with: event)
        } else {
            // Click outside pie menu - request dismissal
            print("FullScreenEventView: Click outside pie menu, requesting dismissal")
            pieMenuView.delegate?.pieMenuViewDidRequestDismissal(pieMenuView)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        // Forward mouse moved events to pie menu view if within bounds
        guard let pieMenuView = pieMenuView else { return }

        let windowPoint = event.locationInWindow
        let pieMenuFrame = pieMenuView.frame

        if pieMenuFrame.contains(windowPoint) {
            pieMenuView.mouseMoved(with: event)
        }
    }
}
