//
//  ErrorHandler.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

/// Centralized error handling and user notification system
class ErrorHandler: ObservableObject {
    
    /// Singleton instance
    static let shared = ErrorHandler()
    
    /// Published error state for UI binding
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    private init() {}
    
    // MARK: - Error Handling
    
    /// Handle an error with appropriate user feedback
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Additional context about where the error occurred
    ///   - showAlert: Whether to show an alert dialog
    func handleError(_ error: Error, context: String = "", showAlert: Bool = true) {
        let appError = AppError.from(error, context: context)
        
        // Log the error
        logError(appError)
        
        // Update published state
        DispatchQueue.main.async {
            self.currentError = appError
            self.isShowingError = showAlert
        }
        
        // Show alert if requested
        if showAlert {
            showErrorAlert(appError)
        }
        
        // Send notification
        NotificationCenter.default.post(
            name: .errorOccurred,
            object: appError,
            userInfo: ["context": context]
        )
    }
    
    /// Handle a specific app error
    /// - Parameters:
    ///   - appError: The app error to handle
    ///   - showAlert: Whether to show an alert dialog
    func handleAppError(_ appError: AppError, showAlert: Bool = true) {
        // Log the error
        logError(appError)
        
        // Update published state
        DispatchQueue.main.async {
            self.currentError = appError
            self.isShowingError = showAlert
        }
        
        // Show alert if requested
        if showAlert {
            showErrorAlert(appError)
        }
    }
    
    /// Clear the current error
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.isShowingError = false
        }
    }
    
    // MARK: - User Notifications
    
    /// Show a success notification
    /// - Parameter message: Success message to display
    func showSuccess(_ message: String) {
        showNotification(title: "成功", message: message, type: .success)
    }
    
    /// Show an info notification
    /// - Parameter message: Info message to display
    func showInfo(_ message: String) {
        showNotification(title: "信息", message: message, type: .info)
    }
    
    /// Show a warning notification
    /// - Parameter message: Warning message to display
    func showWarning(_ message: String) {
        showNotification(title: "警告", message: message, type: .warning)
    }
    
    // MARK: - Private Methods
    
    private func logError(_ error: AppError) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] ERROR: \(error.title) - \(error.message)"
        
        if !error.context.isEmpty {
            print("\(logMessage) (Context: \(error.context))")
        } else {
            print(logMessage)
        }
        
        // In a production app, you might want to log to a file or crash reporting service
    }
    
    private func showErrorAlert(_ error: AppError) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = error.title
            alert.informativeText = error.message
            alert.alertStyle = error.severity.alertStyle
            
            // Add primary button
            alert.addButton(withTitle: "确定")
            
            // Add recovery action if available
            if let recoveryAction = error.recoveryAction {
                alert.addButton(withTitle: recoveryAction.title)
            }
            
            let response = alert.runModal()
            
            // Handle recovery action
            if response == .alertSecondButtonReturn, let recoveryAction = error.recoveryAction {
                recoveryAction.action()
            }
        }
    }
    
    private func showNotification(title: String, message: String, type: NotificationType) {
        // For now, just print to console
        // In a production app, you might use NSUserNotification or a toast library
        print("[\(type.rawValue.uppercased())] \(title): \(message)")
        
        // You could also show a temporary overlay or use the system notification center
        if type == .success {
            DispatchQueue.main.async {
                // Show brief success indicator
            }
        }
    }
}

// MARK: - Supporting Types

/// Application-specific error type
struct AppError {
    let title: String
    let message: String
    let severity: ErrorSeverity
    let context: String
    let recoveryAction: RecoveryAction?
    
    init(title: String, message: String, severity: ErrorSeverity = .error, context: String = "", recoveryAction: RecoveryAction? = nil) {
        self.title = title
        self.message = message
        self.severity = severity
        self.context = context
        self.recoveryAction = recoveryAction
    }
    
    /// Create an AppError from a system error
    static func from(_ error: Error, context: String = "") -> AppError {
        switch error {
        case let eventError as EventMonitorError:
            return AppError(
                title: "事件监听错误",
                message: eventError.localizedDescription,
                severity: .error,
                context: context,
                recoveryAction: eventError.recoverySuggestion != nil ? RecoveryAction(title: "解决", action: {}) : nil
            )
            
        case let configError as ConfigError:
            return AppError(
                title: "配置错误",
                message: configError.localizedDescription,
                severity: .warning,
                context: context
            )
            
        case let shortcutError as ShortcutExecutionError:
            return AppError(
                title: "快捷键执行错误",
                message: shortcutError.localizedDescription,
                severity: .warning,
                context: context
            )
            
        default:
            return AppError(
                title: "未知错误",
                message: error.localizedDescription,
                severity: .error,
                context: context
            )
        }
    }
}

/// Error severity levels
enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
    
    var alertStyle: NSAlert.Style {
        switch self {
        case .info: return .informational
        case .warning: return .warning
        case .error, .critical: return .critical
        }
    }
}

/// Recovery action for errors
struct RecoveryAction {
    let title: String
    let action: () -> Void
}

/// Notification types
enum NotificationType: String {
    case success
    case info
    case warning
    case error
}

// MARK: - Extensions

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

extension Notification.Name {
    static let errorOccurred = Notification.Name("ErrorOccurred")
}
