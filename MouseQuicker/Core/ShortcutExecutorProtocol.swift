//
//  ShortcutExecutorProtocol.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

/// Protocol defining the interface for executing keyboard shortcuts
protocol ShortcutExecutorProtocol: AnyObject {
    /// Execute a keyboard shortcut
    /// - Parameter shortcut: The keyboard shortcut to execute
    /// - Returns: True if execution was successful, false otherwise
    func execute(_ shortcut: KeyboardShortcut) -> Bool
    
    /// Check if a shortcut can be executed
    /// - Parameter shortcut: The keyboard shortcut to validate
    /// - Returns: True if the shortcut is valid and can be executed
    func canExecute(_ shortcut: KeyboardShortcut) -> Bool
    
    /// Execute a shortcut item (convenience method)
    /// - Parameter item: The shortcut item to execute
    /// - Returns: True if execution was successful, false otherwise
    func executeShortcutItem(_ item: ShortcutItem) -> Bool

    /// Execute a shortcut item in the context of a specific application
    /// - Parameters:
    ///   - item: The shortcut item to execute
    ///   - targetApplication: The application to send the shortcut to
    /// - Returns: True if execution was successful, false otherwise
    func executeShortcutItem(_ item: ShortcutItem, targetApplication: NSRunningApplication) -> Bool
}

/// Errors that can occur during shortcut execution
enum ShortcutExecutionError: Error, LocalizedError {
    case invalidShortcut
    case permissionDenied
    case systemEventCreationFailed
    case executionTimeout
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidShortcut:
            return "无效的快捷键配置"
        case .permissionDenied:
            return "没有权限执行快捷键"
        case .systemEventCreationFailed:
            return "无法创建系统事件"
        case .executionTimeout:
            return "快捷键执行超时"
        case .unknownError(let message):
            return "未知错误: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidShortcut:
            return "请检查快捷键配置是否正确"
        case .permissionDenied:
            return "请在系统偏好设置中启用输入监控权限"
        case .systemEventCreationFailed:
            return "请重启应用程序"
        case .executionTimeout:
            return "请检查系统是否响应正常"
        case .unknownError:
            return "请重试或联系技术支持"
        }
    }
}

/// Result of shortcut execution
struct ShortcutExecutionResult {
    let success: Bool
    let error: ShortcutExecutionError?
    let executionTime: TimeInterval
    
    init(success: Bool, error: ShortcutExecutionError? = nil, executionTime: TimeInterval = 0) {
        self.success = success
        self.error = error
        self.executionTime = executionTime
    }
}
