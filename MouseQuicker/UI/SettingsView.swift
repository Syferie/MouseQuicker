//
//  SettingsView.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import SwiftUI

/// Complete settings view for MouseQuicker
struct SettingsView: View {
    @ObservedObject private var permissionManager = PermissionManager.shared
    @ObservedObject private var appCoordinator = AppCoordinator.shared
    @ObservedObject private var configManager = ConfigManager.shared

    @State private var selectedTab = 0
    @State private var showingAddShortcut = false
    @State private var showingImportExport = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // General Tab
            GeneralSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("通用")
                }
                .tag(0)

            // Shortcuts Tab
            ShortcutsSettingsView()
                .tabItem {
                    Image(systemName: "keyboard")
                    Text("快捷键")
                }
                .tag(1)

            // Appearance Tab
            AppearanceSettingsView()
                .tabItem {
                    Image(systemName: "paintbrush")
                    Text("外观")
                }
                .tag(2)

            // Advanced Tab
            AdvancedSettingsView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver")
                    Text("高级")
                }
                .tag(3)
        }
        .frame(width: 600, height: 500)
        .withNotifications()
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject private var permissionManager = PermissionManager.shared
    @ObservedObject private var appCoordinator = AppCoordinator.shared
    @ObservedObject private var configManager = ConfigManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("通用设置")
                .font(.title2)
                .padding(.top)

            // Permission Status
            GroupBox("权限状态") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: permissionManager.hasAccessibilityPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permissionManager.hasAccessibilityPermission ? .green : .red)
                        Text("辅助功能权限")
                        Spacer()
                        if !permissionManager.hasAccessibilityPermission {
                            Button("授权") {
                                permissionManager.requestAccessibilityPermission()
                            }
                        }
                    }

                    HStack {
                        Image(systemName: permissionManager.hasInputMonitoringPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permissionManager.hasInputMonitoringPermission ? .green : .red)
                        Text("输入监控权限")
                        Spacer()
                        if !permissionManager.hasInputMonitoringPermission {
                            Button("授权") {
                                permissionManager.requestInputMonitoringPermission()
                            }
                        }
                    }
                }
                .padding()
            }

            // App Status
            GroupBox("应用状态") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: appCoordinator.isRunning ? "play.circle.fill" : "pause.circle.fill")
                            .foregroundColor(appCoordinator.isRunning ? .green : .orange)
                        Text(appCoordinator.isRunning ? "运行中" : "已停止")
                        Spacer()
                        Button(appCoordinator.isRunning ? "停止" : "启动") {
                            if appCoordinator.isRunning {
                                appCoordinator.stop()
                            } else {
                                appCoordinator.start()
                            }
                        }
                    }

                    // Trigger Duration Setting
                    VStack(alignment: .leading, spacing: 5) {
                        Text("触发延迟: \(String(format: "%.1f", configManager.currentConfig.triggerDuration))秒")
                        Slider(
                            value: Binding(
                                get: { configManager.currentConfig.triggerDuration },
                                set: { newValue in
                                    try? configManager.updateTriggerDuration(newValue)
                                }
                            ),
                            in: 0.3...0.5,
                            step: 0.1
                        )
                    }
                }
                .padding()
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    @ObservedObject private var configManager = ConfigManager.shared
    @State private var showingAddShortcut = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("快捷键配置")
                    .font(.title2)
                Spacer()
                Button("添加快捷键") {
                    showingAddShortcut = true
                }
            }
            .padding(.top)

            // Shortcuts List
            List {
                ForEach(configManager.currentConfig.shortcutItems) { item in
                    ShortcutItemRow(item: item)
                }
            }
            .frame(minHeight: 300)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAddShortcut) {
            AddShortcutView()
        }
    }
}

struct ShortcutItemRow: View {
    let item: ShortcutItem
    @ObservedObject private var configManager = ConfigManager.shared

    var body: some View {
        HStack {
            Image(systemName: item.iconName)
                .frame(width: 20)

            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                Text(item.shortcut.displayString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { newValue in
                    let updatedItem = item.with(isEnabled: newValue)
                    try? configManager.updateShortcutItem(updatedItem)
                }
            ))

            Button("删除") {
                try? configManager.removeShortcutItem(id: item.id)
            }
            .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @ObservedObject private var configManager = ConfigManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("外观设置")
                .font(.title2)
                .padding(.top)

            GroupBox("菜单外观") {
                VStack(alignment: .leading, spacing: 15) {
                    // Transparency
                    VStack(alignment: .leading) {
                        Text("透明度: \(Int(configManager.currentConfig.menuAppearance.transparency * 100))%")
                        Slider(
                            value: Binding(
                                get: { configManager.currentConfig.menuAppearance.transparency },
                                set: { newValue in
                                    let newAppearance = MenuAppearance(
                                        transparency: newValue,
                                        accentColor: configManager.currentConfig.menuAppearance.accentColor,
                                        menuSize: configManager.currentConfig.menuAppearance.menuSize
                                    )
                                    try? configManager.updateMenuAppearance(newAppearance)
                                }
                            ),
                            in: 0.3...1.0
                        )
                    }

                    // Menu Size
                    VStack(alignment: .leading) {
                        Text("菜单大小: \(Int(configManager.currentConfig.menuAppearance.menuSize))")
                        Slider(
                            value: Binding(
                                get: { configManager.currentConfig.menuAppearance.menuSize },
                                set: { newValue in
                                    let newAppearance = MenuAppearance(
                                        transparency: configManager.currentConfig.menuAppearance.transparency,
                                        accentColor: configManager.currentConfig.menuAppearance.accentColor,
                                        menuSize: newValue
                                    )
                                    try? configManager.updateMenuAppearance(newAppearance)
                                }
                            ),
                            in: 150...300
                        )
                    }
                }
                .padding()
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @ObservedObject private var configManager = ConfigManager.shared
    @State private var showingImportExport = false

    var body: some View {
        VStack(spacing: 20) {
            Text("高级设置")
                .font(.title2)
                .padding(.top)

            GroupBox("配置管理") {
                VStack(spacing: 10) {
                    Button("导出配置") {
                        exportConfiguration()
                    }

                    Button("导入配置") {
                        importConfiguration()
                    }

                    Button("重置为默认") {
                        resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
                .padding()
            }

            GroupBox("调试信息") {
                VStack(alignment: .leading, spacing: 5) {
                    Text("配置版本: \(configManager.currentConfig.version)")
                    Text("快捷键数量: \(configManager.currentConfig.shortcutItems.count)")
                    Text("触发延迟: \(configManager.currentConfig.triggerDuration)秒")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("性能监控") {
                PerformanceView()
                    .padding()
            }

            Spacer()
        }
        .padding()
    }

    private func exportConfiguration() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MouseQuicker_Config.json"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try configManager.exportToFile(url: url)
            } catch {
                print("Export failed: \(error)")
            }
        }
    }

    private func importConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.urls.first {
            do {
                let _ = try configManager.importFromFile(url: url)
            } catch {
                print("Import failed: \(error)")
            }
        }
    }

    private func resetToDefaults() {
        try? configManager.resetToDefaults()
    }
}

// MARK: - Add Shortcut View

struct AddShortcutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var configManager = ConfigManager.shared

    @State private var title = ""
    @State private var selectedKey: KeyCode = .a
    @State private var selectedModifiers: Set<ModifierKey> = [.command]
    @State private var selectedIcon = "keyboard"

    var body: some View {
        VStack(spacing: 20) {
            Text("添加新快捷键")
                .font(.title2)

            Form {
                TextField("标题", text: $title)

                Picker("主键", selection: $selectedKey) {
                    ForEach(KeyCode.allCases, id: \.self) { key in
                        Text(key.displayName).tag(key)
                    }
                }

                // Modifier selection would go here

                TextField("图标名称", text: $selectedIcon)
            }

            HStack {
                Button("取消") {
                    dismiss()
                }

                Button("添加") {
                    addShortcut()
                }
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    private func addShortcut() {
        let shortcut = KeyboardShortcut(primaryKey: selectedKey, modifiers: selectedModifiers)
        let item = ShortcutItem(title: title, shortcut: shortcut, iconName: selectedIcon)

        try? configManager.addShortcutItem(item)
        dismiss()
    }
}

// MARK: - Performance View

struct PerformanceView: View {
    @ObservedObject private var performanceMonitor = PerformanceMonitor.shared
    @State private var showOptimizations = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("性能监控")
                    .font(.headline)
                Spacer()
                Button("优化建议") {
                    showOptimizations.toggle()
                }
            }

            // Memory usage
            HStack {
                Text("内存使用:")
                Spacer()
                Text("\(String(format: "%.1f", performanceMonitor.metrics.memoryUsage)) MB")
                    .foregroundColor(performanceMonitor.metrics.memoryUsage > 50 ? .red : .primary)
            }

            // Timing information
            if !performanceMonitor.metrics.timings.isEmpty {
                Divider()
                Text("性能计时:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ForEach(Array(performanceMonitor.metrics.timings.keys.sorted()), id: \.self) { key in
                    if let timing = performanceMonitor.metrics.timings[key] {
                        HStack {
                            Text(key)
                                .font(.caption)
                            Spacer()
                            Text("\(String(format: "%.2f", timing.averageDuration * 1000))ms")
                                .font(.caption)
                                .foregroundColor(timing.averageDuration > 0.016 ? .orange : .secondary)
                        }
                    }
                }
            }

            // Reset button
            HStack {
                Spacer()
                Button("重置统计") {
                    performanceMonitor.resetMetrics()
                }
                .font(.caption)
            }
        }
        .sheet(isPresented: $showOptimizations) {
            OptimizationSuggestionsView()
        }
    }
}

// MARK: - Optimization Suggestions View

struct OptimizationSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    private let suggestions = PerformanceMonitor.shared.getOptimizationSuggestions()

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("性能优化建议")
                    .font(.title2)
                Spacer()
                Button("关闭") {
                    dismiss()
                }
            }

            if suggestions.isEmpty {
                Text("当前性能良好，无需优化")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(suggestions.indices, id: \.self) { index in
                    let suggestion = suggestions[index]
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: iconForSuggestionType(suggestion.type))
                                .foregroundColor(colorForPriority(suggestion.priority))
                            Text(suggestion.description)
                                .font(.body)
                            Spacer()
                        }

                        Text("优先级: \(priorityText(suggestion.priority))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }

    private func iconForSuggestionType(_ type: OptimizationSuggestion.SuggestionType) -> String {
        switch type {
        case .memory: return "memorychip"
        case .performance: return "speedometer"
        case .ui: return "paintbrush"
        case .network: return "network"
        }
    }

    private func colorForPriority(_ priority: OptimizationSuggestion.Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }

    private func priorityText(_ priority: OptimizationSuggestion.Priority) -> String {
        switch priority {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "紧急"
        }
    }
}

#Preview {
    SettingsView()
}
