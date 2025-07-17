//
//  ConfigManagerProtocol.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation

/// Protocol defining the interface for configuration management
protocol ConfigManagerProtocol: AnyObject {
    /// Load the current application configuration
    /// - Returns: The loaded configuration or default if none exists
    func loadConfiguration() -> AppConfig
    
    /// Save the application configuration
    /// - Parameter config: The configuration to save
    /// - Throws: ConfigError if saving fails
    func saveConfiguration(_ config: AppConfig) throws
    
    /// Export configuration to data
    /// - Returns: JSON data representing the configuration
    /// - Throws: ConfigError if export fails
    func exportConfiguration() throws -> Data
    
    /// Import configuration from data
    /// - Parameter data: JSON data containing configuration
    /// - Returns: True if import was successful
    /// - Throws: ConfigError if import fails
    func importConfiguration(from data: Data) throws -> Bool
    
    /// Reset configuration to defaults
    /// - Throws: ConfigError if reset fails
    func resetToDefaults() throws
    
    /// Validate a configuration
    /// - Parameter config: The configuration to validate
    /// - Returns: True if configuration is valid
    func validateConfiguration(_ config: AppConfig) -> Bool
    
    /// Get the default configuration
    /// - Returns: A default configuration instance
    func defaultConfiguration() -> AppConfig
}

/// Errors that can occur during configuration management
enum ConfigError: Error, LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    case exportFailed(String)
    case importFailed(String)
    case validationFailed(String)
    case corruptedData
    case unsupportedVersion
    case fileNotFound
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let reason):
            return "配置加载失败: \(reason)"
        case .saveFailed(let reason):
            return "配置保存失败: \(reason)"
        case .exportFailed(let reason):
            return "配置导出失败: \(reason)"
        case .importFailed(let reason):
            return "配置导入失败: \(reason)"
        case .validationFailed(let reason):
            return "配置验证失败: \(reason)"
        case .corruptedData:
            return "配置数据已损坏"
        case .unsupportedVersion:
            return "不支持的配置版本"
        case .fileNotFound:
            return "配置文件未找到"
        case .permissionDenied:
            return "没有权限访问配置文件"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadFailed, .corruptedData, .unsupportedVersion:
            return "将使用默认配置，您可以重新配置应用设置"
        case .saveFailed, .permissionDenied:
            return "请检查文件权限或磁盘空间"
        case .exportFailed:
            return "请选择其他位置或检查磁盘空间"
        case .importFailed, .validationFailed:
            return "请检查配置文件格式是否正确"
        case .fileNotFound:
            return "将创建新的配置文件"
        }
    }
}

/// Notification names for configuration changes
extension Notification.Name {
    static let configurationDidChange = Notification.Name("ConfigurationDidChange")
    static let configurationDidReset = Notification.Name("ConfigurationDidReset")
    static let configurationDidImport = Notification.Name("ConfigurationDidImport")
}
