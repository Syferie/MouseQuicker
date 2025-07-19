//
//  EventMonitor.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

/// Implementation of global event monitoring for mouse interactions
class EventMonitor: EventMonitorProtocol {
    
    // MARK: - Properties

    weak var delegate: EventMonitorDelegate?
    var triggerDuration: TimeInterval = 0.4
    var triggerButton: TriggerButton = .middle
    var isMonitoring: Bool = false

    // MARK: - Private Properties

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var triggerTimer: Timer?
    private var triggerStartTime: Date?
    private var triggerLocation: NSPoint = .zero
    private var isTriggerButtonPressed = false
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        stopMonitoring()
        // 确保所有定时器都被清理
        triggerTimer?.invalidate()
        triggerTimer = nil
    }
    
    // MARK: - EventMonitorProtocol Implementation
    
    func startMonitoring() throws {
        guard !isMonitoring else {
            throw EventMonitorError.monitoringAlreadyActive
        }

        // Check permissions
        guard PermissionManager.shared.checkAccessibilityPermission() else {
            throw EventMonitorError.accessibilityPermissionDenied
        }

        // Get event types for the current trigger button
        let eventTypes = triggerButton.eventTypes
        var eventMask: NSEvent.EventTypeMask = []
        eventMask.insert(NSEvent.EventTypeMask(rawValue: 1 << eventTypes.down.rawValue))
        eventMask.insert(NSEvent.EventTypeMask(rawValue: 1 << eventTypes.up.rawValue))
        eventMask.insert(NSEvent.EventTypeMask(rawValue: 1 << eventTypes.dragged.rawValue))

        // Set up global event monitor for mouse events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleGlobalMouseEvent(event)
        }

        // Set up local event monitor for when app is active
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            guard let self = self else { return event }

            self.handleLocalMouseEvent(event)

            // For right-click, we need special handling to suppress the system context menu
            if self.triggerButton == .right {
                let eventTypes = self.triggerButton.eventTypes

                // Suppress right-click down events during trigger detection
                if event.type == eventTypes.down && event.buttonNumber == self.triggerButton.buttonNumber {
                    return nil // Suppress the event to prevent context menu
                }

                // Also suppress right-click up events if we're in trigger mode
                if event.type == eventTypes.up && self.isTriggerButtonPressed {
                    return nil // Suppress to prevent delayed context menu
                }
            }

            return event
        }

        guard globalMonitor != nil else {
            throw EventMonitorError.systemEventMonitorFailed
        }

        isMonitoring = true
        print("EventMonitor: Started monitoring global mouse events for \(triggerButton.displayName)")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        // Remove global monitor
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        
        // Remove local monitor
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        
        // Cancel any active trigger
        cancelTrigger()
        
        isMonitoring = false
        print("EventMonitor: Stopped monitoring global mouse events")
    }
    
    func updateTriggerDuration(_ duration: TimeInterval) {
        triggerDuration = max(0.1, min(1.0, duration))
        print("EventMonitor: Updated trigger duration to \(triggerDuration)")
    }

    func updateTriggerButton(_ button: TriggerButton) {
        let wasMonitoring = isMonitoring

        // Stop monitoring if currently active
        if wasMonitoring {
            stopMonitoring()
        }

        // Update the trigger button
        triggerButton = button
        print("EventMonitor: Updated trigger button to \(button.displayName)")

        // Restart monitoring if it was active
        if wasMonitoring {
            try? startMonitoring()
        }
    }
    
    // MARK: - Private Event Handling
    
    private func handleGlobalMouseEvent(_ event: NSEvent) {
        handleMouseEvent(event)
    }
    
    private func handleLocalMouseEvent(_ event: NSEvent) {
        handleMouseEvent(event)
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        // Performance optimization: early return for non-trigger button events
        guard event.buttonNumber == triggerButton.buttonNumber else { return }

        // Use performance monitoring
        withPerformanceMeasurement(label: "EventMonitor") {
            let eventTypes = triggerButton.eventTypes
            switch event.type {
            case eventTypes.down:
                handleTriggerButtonDown(event)
            case eventTypes.up:
                handleTriggerButtonUp(event)
            case eventTypes.dragged:
                handleTriggerButtonDragged(event)
            default:
                break
            }
        }
    }
    
    private func handleTriggerButtonDown(_ event: NSEvent) {
        guard !isTriggerButtonPressed else { return }

        isTriggerButtonPressed = true
        triggerStartTime = Date()
        triggerLocation = event.locationInWindow

        // Convert to screen coordinates
        if let window = event.window {
            triggerLocation = window.convertToScreen(NSRect(origin: triggerLocation, size: .zero)).origin
        } else {
            triggerLocation = NSEvent.mouseLocation
        }

        // For right-click, we need to suppress system context menu
        if triggerButton == .right {
            // Disable system context menu temporarily
            suppressSystemContextMenu()
        }

        // Start trigger timer
        triggerTimer = Timer.scheduledTimer(withTimeInterval: triggerDuration, repeats: false) { [weak self] _ in
            self?.triggerActivated()
        }

        print("EventMonitor: \(triggerButton.displayName) pressed at \(triggerLocation)")
    }
    
    private func handleTriggerButtonUp(_ event: NSEvent) {
        guard isTriggerButtonPressed else { return }

        let wasTriggered = triggerTimer == nil // Timer was already fired
        cancelTrigger()

        if !wasTriggered {
            // Button was released before trigger duration
            delegate?.eventMonitor(self, didCancelTrigger: ())
            print("EventMonitor: Trigger cancelled - \(triggerButton.displayName) released too early")
        }
    }
    
    private func handleTriggerButtonDragged(_ event: NSEvent) {
        // If user drags while holding trigger button, cancel the trigger
        guard isTriggerButtonPressed else { return }

        let currentLocation = NSEvent.mouseLocation
        let distance = sqrt(pow(currentLocation.x - triggerLocation.x, 2) + pow(currentLocation.y - triggerLocation.y, 2))

        // Cancel if moved more than 10 pixels
        if distance > 10 {
            cancelTrigger()
            delegate?.eventMonitor(self, didCancelTrigger: ())
            print("EventMonitor: Trigger cancelled - mouse moved too much while holding \(triggerButton.displayName)")
        }
    }
    
    private func triggerActivated() {
        guard isTriggerButtonPressed else { return }

        print("EventMonitor: Trigger activated at \(triggerLocation) with \(triggerButton.displayName)")

        // Clear the timer since it fired
        triggerTimer?.invalidate()
        triggerTimer = nil

        // Notify delegate
        delegate?.eventMonitor(self, didDetectTriggerAt: triggerLocation)
    }

    private func cancelTrigger() {
        isTriggerButtonPressed = false
        triggerStartTime = nil

        triggerTimer?.invalidate()
        triggerTimer = nil

        // Re-enable system context menu if it was disabled
        if triggerButton == .right {
            restoreSystemContextMenu()
        }
    }

    // MARK: - Right-click Context Menu Handling

    private func suppressSystemContextMenu() {
        // For right-click handling, we use a different approach
        // We'll handle this through the local monitor return value
        print("EventMonitor: Suppressing system context menu for right-click")
    }

    private func restoreSystemContextMenu() {
        // Restore normal right-click behavior
        print("EventMonitor: Restoring system context menu for right-click")
    }
    
    // MARK: - Utility Methods
    
    /// Check if the system supports middle mouse button detection
    func supportsMiddleButton() -> Bool {
        // Most modern mice support middle button, but we can check if we can detect it
        return true
    }
    
    /// Get current mouse location in screen coordinates
    func getCurrentMouseLocation() -> NSPoint {
        return NSEvent.mouseLocation
    }
    
    /// Test if event monitoring is working
    func testEventMonitoring() -> Bool {
        return isMonitoring && globalMonitor != nil
    }
}

// MARK: - Debug Extensions

extension EventMonitor {
    /// Enable debug logging for event monitoring
    var debugLogging: Bool {
        get { UserDefaults.standard.bool(forKey: "EventMonitorDebugLogging") }
        set { UserDefaults.standard.set(newValue, forKey: "EventMonitorDebugLogging") }
    }
    
    private func debugLog(_ message: String) {
        if debugLogging {
            print("EventMonitor Debug: \(message)")
        }
    }
}
