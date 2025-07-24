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
        // 使用真正的 HUD/Overlay 无焦点浮层设置

        // 设置为最高级别的浮层，但不抢夺焦点
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))

        // 窗口基本属性
        isOpaque = false
        backgroundColor = NSColor.clear
        hasShadow = true
        ignoresMouseEvents = false

        // 关键：完全禁用焦点相关行为
        collectionBehavior = [
            .canJoinAllSpaces,           // 可以在所有空间显示
            .fullScreenAuxiliary,        // 全屏辅助窗口
            .ignoresCycle,               // 不参与窗口循环
            .stationary,                 // 静态窗口，不跟随空间切换
            .participatesInCycle         // 但允许参与某些系统行为
        ]

        // 鼠标事件处理
        acceptsMouseMovedEvents = true

        // 窗口生命周期
        isReleasedWhenClosed = false
        canHide = false
        hidesOnDeactivate = false

        // 完全禁用窗口激活和焦点获取
        isExcludedFromWindowsMenu = true

        print("PieMenuWindow: Configured as true HUD overlay with no focus stealing")
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

        // Calculate menu size based on the maximum possible radius (outer radius * 2 + padding)
        let maxRadius = pieMenuView.getMaxRadius()
        let menuSize = maxRadius * 2 + 20 // Add some padding

        let menuFrame = NSRect(
            x: location.x - menuSize / 2,
            y: location.y - menuSize / 2,
            width: menuSize,
            height: menuSize
        )

        // Update the pie menu view frame
        pieMenuView.frame = menuFrame

        print("PieMenuWindow: Positioned menu at \(location), menuFrame=\(menuFrame), maxRadius=\(maxRadius)")
    }
    
    /// Show the window with animation
    func showAnimated(completion: @escaping () -> Void = {}) {
        // 确保菜单视图处于隐藏状态
        pieMenuView.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1.0)
        pieMenuView.layer?.opacity = 0.0

        // 使用最安全的 HUD 显示方式
        if !isVisible {
            // 使用 orderFrontRegardless 是 HUD 窗口的标准做法
            // 这确保窗口显示但不会抢夺任何焦点
            orderFrontRegardless()

            // 额外确保：显示后立即确认不会成为关键窗口
            DispatchQueue.main.async { [weak self] in
                if let self = self, self.isKeyWindow {
                    // 如果意外成为了关键窗口，立即放弃关键状态
                    self.resignKey()
                    print("PieMenuWindow: Emergency focus release - resigned key status")
                }
            }
        }

        // 立即开始动画
        pieMenuView.animateAppearance(completion: completion)

        print("PieMenuWindow: HUD overlay displayed without focus stealing")
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
        // 绝对不能成为关键窗口 - 这是 HUD 的核心特性
        return false
    }

    override var canBecomeMain: Bool {
        // 绝对不能成为主窗口 - 保持目标应用的主窗口状态
        return false
    }

    override var acceptsFirstResponder: Bool {
        // 不接受第一响应者状态，避免键盘焦点转移
        return false
    }

    override func becomeKey() {
        // 重写 becomeKey 方法，确保永远不会成为关键窗口
        // 不调用 super.becomeKey()
        print("PieMenuWindow: Prevented from becoming key window")
    }

    override func makeKey() {
        // 重写 makeKey 方法，确保永远不会被设为关键窗口
        // 不调用 super.makeKey()
        print("PieMenuWindow: Prevented from being made key window")
    }

    override func orderFront(_ sender: Any?) {
        // 使用 orderFrontRegardless 来显示窗口，但不改变焦点
        orderFrontRegardless()
    }

    override func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        // 确保窗口排序操作不会影响焦点
        if place == .above || place == .out {
            super.order(place, relativeTo: otherWin)
        }
        // 忽略其他可能影响焦点的排序操作
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
            // Convert to pie menu view coordinates and check if it's actually within the menu area
            let localPoint = pieMenuView.convert(windowPoint, from: nil)
            let sectorIndex = pieMenuView.sectorIndex(for: localPoint)

            if sectorIndex >= 0 {
                // Click is within a menu sector, forward the event
                print("FullScreenEventView: Click within menu sector \(sectorIndex), forwarding event")
                pieMenuView.mouseDown(with: event)
            } else {
                // Click is within frame but outside menu sectors, dismiss
                print("FullScreenEventView: Click within frame but outside menu sectors, requesting dismissal")
                pieMenuView.delegate?.pieMenuViewDidRequestDismissal(pieMenuView)
            }
        } else {
            // Click outside pie menu frame - request dismissal
            print("FullScreenEventView: Click outside pie menu frame, requesting dismissal")
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
