//
//  EventMonitorProtocol.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

/// Delegate protocol for EventMonitor to communicate trigger events
protocol EventMonitorDelegate: AnyObject {
    /// Called when a valid trigger is detected (middle button long press)
    /// - Parameters:
    ///   - monitor: The EventMonitor instance
    ///   - location: The mouse location where the trigger occurred
    func eventMonitor(_ monitor: EventMonitor, didDetectTriggerAt location: NSPoint)
    
    /// Called when a trigger is cancelled (button released too early)
    /// - Parameter monitor: The EventMonitor instance
    func eventMonitor(_ monitor: EventMonitor, didCancelTrigger: Void)
}

/// Protocol defining the interface for global event monitoring
protocol EventMonitorProtocol: AnyObject {
    /// Delegate to receive trigger notifications
    var delegate: EventMonitorDelegate? { get set }

    /// Duration required for trigger activation (0.1-1.0 seconds)
    var triggerDuration: TimeInterval { get set }

    /// Button used for triggering
    var triggerButton: TriggerButton { get set }

    /// Whether the monitor is currently active
    var isMonitoring: Bool { get }

    /// Start monitoring for global mouse events
    /// - Throws: EventMonitorError if monitoring cannot be started
    func startMonitoring() throws

    /// Stop monitoring for global mouse events
    func stopMonitoring()

    /// Update the trigger duration
    /// - Parameter duration: New duration in seconds (must be between 0.1-1.0)
    func updateTriggerDuration(_ duration: TimeInterval)

    /// Update the trigger button
    /// - Parameter button: New trigger button to monitor
    func updateTriggerButton(_ button: TriggerButton)
}

/// Errors that can occur during event monitoring
enum EventMonitorError: Error, LocalizedError {
    case accessibilityPermissionDenied
    case inputMonitoringPermissionDenied
    case monitoringAlreadyActive
    case systemEventMonitorFailed
    
    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionDenied:
            return "需要辅助功能权限来监听全局鼠标事件"
        case .inputMonitoringPermissionDenied:
            return "需要输入监控权限来检测鼠标按键"
        case .monitoringAlreadyActive:
            return "事件监听已经处于活动状态"
        case .systemEventMonitorFailed:
            return "无法创建系统事件监听器"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .accessibilityPermissionDenied, .inputMonitoringPermissionDenied:
            return "请在系统偏好设置 > 安全性与隐私 > 隐私中启用相应权限"
        case .monitoringAlreadyActive:
            return "请先停止当前监听再重新开始"
        case .systemEventMonitorFailed:
            return "请重启应用程序或联系技术支持"
        }
    }
}
