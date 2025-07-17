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
    var isMonitoring: Bool = false
    
    // MARK: - Private Properties
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var triggerTimer: Timer?
    private var triggerStartTime: Date?
    private var triggerLocation: NSPoint = .zero
    private var isMiddleButtonPressed = false
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        stopMonitoring()
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
        
        // Set up global event monitor for mouse events
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.otherMouseDown, .otherMouseUp, .otherMouseDragged]) { [weak self] event in
            self?.handleGlobalMouseEvent(event)
        }
        
        // Set up local event monitor for when app is active
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.otherMouseDown, .otherMouseUp, .otherMouseDragged]) { [weak self] event in
            self?.handleLocalMouseEvent(event)
            return event
        }
        
        guard globalMonitor != nil else {
            throw EventMonitorError.systemEventMonitorFailed
        }
        
        isMonitoring = true
        print("EventMonitor: Started monitoring global mouse events")
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
        triggerDuration = max(0.3, min(0.5, duration))
    }
    
    // MARK: - Private Event Handling
    
    private func handleGlobalMouseEvent(_ event: NSEvent) {
        handleMouseEvent(event)
    }
    
    private func handleLocalMouseEvent(_ event: NSEvent) {
        handleMouseEvent(event)
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        // Performance optimization: early return for non-middle button events
        guard event.buttonNumber == 2 else { return }

        // Use performance monitoring
        withPerformanceMeasurement(label: "EventMonitor") {
            switch event.type {
            case .otherMouseDown:
                handleMiddleButtonDown(event)
            case .otherMouseUp:
                handleMiddleButtonUp(event)
            case .otherMouseDragged:
                handleMiddleButtonDragged(event)
            default:
                break
            }
        }
    }
    
    private func handleMiddleButtonDown(_ event: NSEvent) {
        guard !isMiddleButtonPressed else { return }
        
        isMiddleButtonPressed = true
        triggerStartTime = Date()
        triggerLocation = event.locationInWindow
        
        // Convert to screen coordinates
        if let window = event.window {
            triggerLocation = window.convertToScreen(NSRect(origin: triggerLocation, size: .zero)).origin
        } else {
            triggerLocation = NSEvent.mouseLocation
        }
        
        // Start trigger timer
        triggerTimer = Timer.scheduledTimer(withTimeInterval: triggerDuration, repeats: false) { [weak self] _ in
            self?.triggerActivated()
        }
        
        print("EventMonitor: Middle button pressed at \(triggerLocation)")
    }
    
    private func handleMiddleButtonUp(_ event: NSEvent) {
        guard isMiddleButtonPressed else { return }
        
        let wasTriggered = triggerTimer == nil // Timer was already fired
        cancelTrigger()
        
        if !wasTriggered {
            // Button was released before trigger duration
            delegate?.eventMonitor(self, didCancelTrigger: ())
            print("EventMonitor: Trigger cancelled - button released too early")
        }
    }
    
    private func handleMiddleButtonDragged(_ event: NSEvent) {
        // If user drags while holding middle button, cancel the trigger
        guard isMiddleButtonPressed else { return }
        
        let currentLocation = NSEvent.mouseLocation
        let distance = sqrt(pow(currentLocation.x - triggerLocation.x, 2) + pow(currentLocation.y - triggerLocation.y, 2))
        
        // Cancel if moved more than 10 pixels
        if distance > 10 {
            cancelTrigger()
            delegate?.eventMonitor(self, didCancelTrigger: ())
            print("EventMonitor: Trigger cancelled - mouse moved too much")
        }
    }
    
    private func triggerActivated() {
        guard isMiddleButtonPressed else { return }
        
        print("EventMonitor: Trigger activated at \(triggerLocation)")
        
        // Clear the timer since it fired
        triggerTimer?.invalidate()
        triggerTimer = nil
        
        // Notify delegate
        delegate?.eventMonitor(self, didDetectTriggerAt: triggerLocation)
    }
    
    private func cancelTrigger() {
        isMiddleButtonPressed = false
        triggerStartTime = nil
        
        triggerTimer?.invalidate()
        triggerTimer = nil
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
