//
//  ConfigManager.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation

/// Implementation of configuration management
class ConfigManager: ConfigManagerProtocol, ObservableObject {
    
    /// Singleton instance
    static let shared = ConfigManager()
    
    /// Published current configuration
    @Published var currentConfig: AppConfig
    
    /// UserDefaults key for storing configuration
    private let configKey = "MouseQuickerConfig"
    
    /// File manager for import/export operations
    private let fileManager = FileManager.default
    
    private init() {
        self.currentConfig = Self.loadConfigurationFromDefaults() ?? AppConfig.default
    }
    
    // MARK: - ConfigManagerProtocol Implementation
    
    func loadConfiguration() -> AppConfig {
        if let config = Self.loadConfigurationFromDefaults() {
            currentConfig = config
            return config
        } else {
            let defaultConfig = AppConfig.default
            currentConfig = defaultConfig
            try? saveConfiguration(defaultConfig)
            return defaultConfig
        }
    }
    
    func saveConfiguration(_ config: AppConfig) throws {
        guard validateConfiguration(config) else {
            throw ConfigError.validationFailed("配置验证失败")
        }

        // Performance optimization: measure save time
        try withPerformanceMeasurement(label: "ConfigSave") {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: configKey)
            currentConfig = config

            // Post notification asynchronously to avoid blocking
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .configurationDidChange, object: config)
            }
        }
    }
    
    func exportConfiguration() throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(currentConfig)
        } catch {
            throw ConfigError.exportFailed("导出失败: \(error.localizedDescription)")
        }
    }
    
    func importConfiguration(from data: Data) throws -> Bool {
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(AppConfig.self, from: data)
            
            guard validateConfiguration(config) else {
                throw ConfigError.validationFailed("导入的配置无效")
            }
            
            try saveConfiguration(config)
            
            // Post notification
            NotificationCenter.default.post(name: .configurationDidImport, object: config)
            
            return true
        } catch let error as ConfigError {
            throw error
        } catch {
            throw ConfigError.importFailed("解析失败: \(error.localizedDescription)")
        }
    }
    
    func resetToDefaults() throws {
        let defaultConfig = AppConfig.default
        try saveConfiguration(defaultConfig)
        
        // Post notification
        NotificationCenter.default.post(name: .configurationDidReset, object: defaultConfig)
    }
    
    func validateConfiguration(_ config: AppConfig) -> Bool {
        // Check trigger duration
        guard config.triggerDuration >= 0.1 && config.triggerDuration <= 1.0 else {
            print("ConfigManager: Validation failed - invalid trigger duration: \(config.triggerDuration)")
            return false
        }
        
        // Check shortcut items count
        guard config.shortcutItems.count <= 20 else {
            print("ConfigManager: Validation failed - too many shortcut items: \(config.shortcutItems.count), maximum is 20")
            return false
        }
        
        // Validate each shortcut item
        for item in config.shortcutItems {
            guard item.shortcut.isValid else {
                return false
            }
        }
        
        return true
    }
    
    func defaultConfiguration() -> AppConfig {
        return AppConfig.default
    }
    
    // MARK: - Private Helper Methods
    
    private static func loadConfigurationFromDefaults() -> AppConfig? {
        guard let data = UserDefaults.standard.data(forKey: "MouseQuickerConfig") else {
            return nil
        }

        do {
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            print("Failed to decode configuration: \(error)")

            // 尝试迁移旧版本配置
            if let migratedConfig = migrateOldConfiguration(from: data) {
                print("Successfully migrated old configuration")
                return migratedConfig
            }

            return nil
        }
    }

    /// 迁移旧版本配置数据
    private static func migrateOldConfiguration(from data: Data) -> AppConfig? {
        do {
            // 尝试解析为旧版本的 ShortcutItem（没有 applicationScope 字段）
            struct OldShortcutItem: Codable {
                let id: UUID
                let title: String
                let shortcut: KeyboardShortcut
                let iconName: String
                let isEnabled: Bool
                let executionMode: ShortcutExecutionMode
            }

            struct OldAppConfig: Codable {
                let shortcutItems: [OldShortcutItem]
                let triggerDuration: TimeInterval
                let triggerButton: TriggerButton
                let menuAppearance: MenuAppearance
                let version: String
            }

            let oldConfig = try JSONDecoder().decode(OldAppConfig.self, from: data)

            // 转换为新版本格式
            let newShortcutItems = oldConfig.shortcutItems.map { oldItem in
                ShortcutItem(
                    id: oldItem.id,
                    title: oldItem.title,
                    shortcut: oldItem.shortcut,
                    iconName: oldItem.iconName,
                    isEnabled: oldItem.isEnabled,
                    executionMode: oldItem.executionMode,
                    applicationScope: .default  // 使用默认应用范围
                )
            }

            return AppConfig(
                shortcutItems: newShortcutItems,
                triggerDuration: oldConfig.triggerDuration,
                triggerButton: oldConfig.triggerButton,
                menuAppearance: oldConfig.menuAppearance,
                version: oldConfig.version
            )

        } catch {
            print("Failed to migrate old configuration: \(error)")
            return nil
        }
    }
    
    // MARK: - File Operations
    
    /// Export configuration to file
    func exportToFile(url: URL) throws {
        let data = try exportConfiguration()
        try data.write(to: url)
    }
    
    /// Import configuration from file
    func importFromFile(url: URL) throws -> Bool {
        let data = try Data(contentsOf: url)
        return try importConfiguration(from: data)
    }
    
    /// Get documents directory for saving/loading files
    func getDocumentsDirectory() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Get default export file URL
    func getDefaultExportURL() -> URL {
        let documentsDir = getDocumentsDirectory()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        return documentsDir.appendingPathComponent("MouseQuicker_Config_\(timestamp).json")
    }
    
    // MARK: - Convenience Methods
    
    /// Add a new shortcut item
    func addShortcutItem(_ item: ShortcutItem) throws {
        // 检查是否已达到最大数量限制
        if currentConfig.shortcutItems.count >= 20 {
            throw ConfigError.validationFailed("已达到最大快捷键数量限制（20个）。请删除一些现有快捷键后再添加新的。")
        }

        var config = currentConfig
        config = AppConfig(
            shortcutItems: config.shortcutItems + [item],
            triggerDuration: config.triggerDuration,
            triggerButton: config.triggerButton,
            menuAppearance: config.menuAppearance,
            version: config.version
        )
        try saveConfiguration(config)
    }
    
    /// Remove a shortcut item by ID
    func removeShortcutItem(id: UUID) throws {
        var config = currentConfig
        config = AppConfig(
            shortcutItems: config.shortcutItems.filter { $0.id != id },
            triggerDuration: config.triggerDuration,
            triggerButton: config.triggerButton,
            menuAppearance: config.menuAppearance,
            version: config.version
        )
        try saveConfiguration(config)
    }
    
    /// Update a shortcut item
    func updateShortcutItem(_ item: ShortcutItem) throws {
        var config = currentConfig
        var items = config.shortcutItems
        
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            config = AppConfig(
                shortcutItems: items,
                triggerDuration: config.triggerDuration,
                triggerButton: config.triggerButton,
                menuAppearance: config.menuAppearance,
                version: config.version
            )
            try saveConfiguration(config)
        }
    }
    
    /// Update trigger duration
    func updateTriggerDuration(_ duration: TimeInterval) throws {
        var config = currentConfig
        config = AppConfig(
            shortcutItems: config.shortcutItems,
            triggerDuration: duration,
            triggerButton: config.triggerButton,
            menuAppearance: config.menuAppearance,
            version: config.version
        )
        try saveConfiguration(config)
    }

    /// Update trigger button
    func updateTriggerButton(_ button: TriggerButton) throws {
        var config = currentConfig
        config = AppConfig(
            shortcutItems: config.shortcutItems,
            triggerDuration: config.triggerDuration,
            triggerButton: button,
            menuAppearance: config.menuAppearance,
            version: config.version
        )
        try saveConfiguration(config)
    }

    /// Update menu appearance
    func updateMenuAppearance(_ appearance: MenuAppearance) throws {
        var config = currentConfig
        config = AppConfig(
            shortcutItems: config.shortcutItems,
            triggerDuration: config.triggerDuration,
            triggerButton: config.triggerButton,
            menuAppearance: appearance,
            version: config.version
        )
        try saveConfiguration(config)
    }
}
