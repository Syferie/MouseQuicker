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

    // 内存管理
    @State private var isViewActive = true

    var body: some View {
        TabView(selection: $selectedTab) {
            // General Tab (merged with advanced and product info)
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
        }
        .frame(width: 650, height: 580)
        .withNotifications()
        .onAppear {
            isViewActive = true
        }
        .onDisappear {
            isViewActive = false
            // 设置面板不是性能瓶颈，不需要特殊清理
        }
    }


}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject private var permissionManager = PermissionManager.shared
    @ObservedObject private var appCoordinator = AppCoordinator.shared
    @ObservedObject private var configManager = ConfigManager.shared
    @State private var showingImportExport = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Product Header
                ProductHeaderView()

                // Permission Status
                ModernGroupBox(title: "权限状态", icon: "shield.checkered") {
                    VStack(spacing: 12) {
                        PermissionRow(
                            title: "辅助功能权限",
                            isGranted: permissionManager.hasAccessibilityPermission,
                            action: { permissionManager.requestAccessibilityPermission() }
                        )

                        Divider()

                        PermissionRow(
                            title: "输入监控权限",
                            isGranted: permissionManager.hasInputMonitoringPermission,
                            action: { permissionManager.requestInputMonitoringPermission() }
                        )
                    }
                }

                // App Control
                ModernGroupBox(title: "应用控制", icon: "power") {
                    VStack(spacing: 16) {
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(appCoordinator.isRunning ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(appCoordinator.isRunning ? "运行中" : "已停止")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            Button(action: {
                                if appCoordinator.isRunning {
                                    appCoordinator.stop()
                                } else {
                                    appCoordinator.start()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: appCoordinator.isRunning ? "stop.fill" : "play.fill")
                                    Text(appCoordinator.isRunning ? "停止" : "启动")
                                }
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(appCoordinator.isRunning ? Color.red : Color.green)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Divider()

                        // Trigger Duration Setting
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("触发延迟")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(String(format: "%.1f", configManager.currentConfig.triggerDuration))秒")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: Binding(
                                    get: { configManager.currentConfig.triggerDuration },
                                    set: { newValue in
                                        try? configManager.updateTriggerDuration(newValue)
                                    }
                                ),
                                in: 0.1...1.0,
                                step: 0.1
                            )
                            .accentColor(.blue)
                        }
                    }
                }

                // Configuration Management
                ModernGroupBox(title: "配置管理", icon: "gear.badge") {
                    VStack(spacing: 12) {
                        Button(action: { showingImportExport = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.on.square")
                                    .foregroundColor(.blue)
                                Text("导入/导出配置")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()

                        Button(action: {
                            try? configManager.resetToDefaults()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.orange)
                                Text("重置为默认设置")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingImportExport) {
            ImportExportView()
        }
    }
}

// MARK: - Modern UI Components

struct ProductHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            // App Icon and Name
            HStack(spacing: 16) {
                // 使用真实的应用图标
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    // 后备方案：渐变背景 + 系统符号
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "cursorarrow.click.2")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("MouseQuicker")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)

                    Text("by Syferie")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Link(destination: URL(string: "https://github.com/Syferie/MouseQuicker")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                Text("GitHub")
                            }
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.blue)
                        }

                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        Text("开源软件")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        )
    }
}

struct ModernGroupBox<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(.body, weight: .medium))

                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)

                Spacer()
            }

            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        )
    }
}

struct PermissionRow: View {
    let title: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isGranted ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)

            Spacer()

            if !isGranted {
                Button("授权") {
                    action()
                }
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                )
                .buttonStyle(PlainButtonStyle())
            } else {
                Text("已授权")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    @ObservedObject private var configManager = ConfigManager.shared
    @State private var showingAddShortcut = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Shortcuts List
                ModernGroupBox(title: "快捷键列表", icon: "command") {
                    VStack(spacing: 12) {
                        // Header with Add Button
                        HStack {
                            Text("已配置的快捷键")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(action: {
                                if configManager.currentConfig.shortcutItems.count < 20 {
                                    showingAddShortcut = true
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .medium))
                                    Text(configManager.currentConfig.shortcutItems.count >= 20 ? "已达上限" : "添加")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(configManager.currentConfig.shortcutItems.count >= 20 ? Color.gray : Color.blue)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(configManager.currentConfig.shortcutItems.count >= 20)
                            .help(configManager.currentConfig.shortcutItems.count >= 20 ? "已达到最大快捷键数量限制（20个）" : "添加新的快捷键")
                        }

                        if configManager.currentConfig.shortcutItems.isEmpty {
                            // Empty State
                            VStack(spacing: 12) {
                                Image(systemName: "command.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary.opacity(0.5))

                                Text("暂无快捷键")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                Text("点击上方「添加」按钮来创建您的第一个快捷键")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        } else {
                            // Shortcuts List
                            LazyVStack(spacing: 8) {
                                ForEach(configManager.currentConfig.shortcutItems) { item in
                                    ModernShortcutItemRow(item: item)
                                }
                            }
                        }
                    }
                }

                // Usage Tips
                ModernGroupBox(title: "使用提示", icon: "lightbulb") {
                    VStack(alignment: .leading, spacing: 12) {
                        TipRow(
                            icon: "hand.point.up",
                            title: "打开菜单",
                            description: "按住鼠标中键等待触发时间后显示菜单"
                        )

                        Divider()

                        TipRow(
                            icon: "hand.tap",
                            title: "选择快捷键",
                            description: "移动鼠标到对应区域，左键点击即可执行"
                        )

                        Divider()

                        TipRow(
                            icon: "escape",
                            title: "取消操作",
                            description: "按 ESC 键或点击菜单外任意区域可取消"
                        )

                        Divider()

                        TipRow(
                            icon: "number.circle",
                            title: "快捷键数量",
                            description: "最多支持 20 个快捷键，超过 10 个时会显示双层菜单"
                        )
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .sheet(isPresented: $showingAddShortcut) {
            AddShortcutView()
        }
    }
}

struct ModernShortcutItemRow: View {
    let item: ShortcutItem
    @ObservedObject private var configManager = ConfigManager.shared
    @State private var showingEditSheet = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(item.isEnabled ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: item.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(item.isEnabled ? .blue : .secondary)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(item.isEnabled ? .primary : .secondary)

                HStack(spacing: 8) {
                    // Shortcut display
                    Text(item.shortcut.displayString)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.isEnabled ? Color.secondary : Color.secondary.opacity(0.5))
                        )

                    // Execution mode indicator
                    HStack(spacing: 4) {
                        Image(systemName: item.executionMode.icon)
                            .font(.system(size: 10))
                        Text(item.executionMode.displayName)
                            .font(.system(.caption2, design: .rounded))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.1))
                    )

                    // Status indicator
                    if !item.isEnabled {
                        Text("已禁用")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.orange.opacity(0.1))
                            )
                    }
                }
            }

            Spacer()

            // Controls
            HStack(spacing: 12) {
                // Enable/Disable toggle
                Toggle("", isOn: Binding(
                    get: { item.isEnabled },
                    set: { newValue in
                        let updatedItem = item.with(isEnabled: newValue)
                        try? configManager.updateShortcutItem(updatedItem)
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .help(item.isEnabled ? "禁用快捷键" : "启用快捷键")

                // Action buttons (show on hover or always on mobile)
                HStack(spacing: 8) {
                    // Edit button
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("编辑快捷键")

                    // Delete button
                    Button(action: {
                        try? configManager.removeShortcutItem(id: item.id)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("删除快捷键")
                }
                .opacity(isHovered ? 1.0 : 0.7)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isHovered ? Color.blue.opacity(0.3) : Color(NSColor.separatorColor),
                            lineWidth: isHovered ? 1.5 : 0.5
                        )
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .sheet(isPresented: $showingEditSheet) {
            EditShortcutView(shortcutItem: item)
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)

                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @ObservedObject private var configManager = ConfigManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Menu Appearance
                ModernGroupBox(title: "菜单外观", icon: "circle.grid.2x2") {
                    VStack(spacing: 16) {
                        // Transparency
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("透明度")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(Int(configManager.currentConfig.menuAppearance.transparency * 100))%")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: Binding(
                                    get: { configManager.currentConfig.menuAppearance.transparency },
                                    set: { newValue in
                                        print("AppearanceSettings: Updating transparency to \(newValue)")
                                        updateMenuAppearance(transparency: newValue)
                                    }
                                ),
                                in: 0.3...1.0,
                                step: 0.05
                            )
                            .accentColor(.blue)
                        }

                        Divider()

                        // Menu Size
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("菜单大小")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(Int(configManager.currentConfig.menuAppearance.menuSize))")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: Binding(
                                    get: { configManager.currentConfig.menuAppearance.menuSize },
                                    set: { newValue in
                                        print("AppearanceSettings: Updating menu size to \(newValue)")
                                        updateMenuAppearance(menuSize: newValue)
                                    }
                                ),
                                in: 150...300,
                                step: 10
                            )
                            .accentColor(.blue)
                        }
                    }
                }

                // Preview
                ModernGroupBox(title: "预览", icon: "eye") {
                    VStack(spacing: 12) {
                        Text("菜单预览")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)

                        // Simple preview circle
                        Circle()
                            .fill(Color.blue.opacity(configManager.currentConfig.menuAppearance.transparency))
                            .frame(width: configManager.currentConfig.menuAppearance.menuSize / 3,
                                   height: configManager.currentConfig.menuAppearance.menuSize / 3)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            )

                        VStack(spacing: 4) {
                            Text("实际大小: \(Int(configManager.currentConfig.menuAppearance.menuSize))px")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("透明度: \(Int(configManager.currentConfig.menuAppearance.transparency * 100))%")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(24)
        }
    }

    private func updateMenuAppearance(
        transparency: Double? = nil,
        menuSize: Double? = nil
    ) {
        let currentAppearance = configManager.currentConfig.menuAppearance
        let newAppearance = MenuAppearance(
            transparency: transparency ?? currentAppearance.transparency,
            accentColor: currentAppearance.accentColor,
            menuSize: menuSize ?? currentAppearance.menuSize
        )

        print("AppearanceSettings: Creating new appearance - transparency: \(newAppearance.transparency), size: \(newAppearance.menuSize)")

        do {
            try configManager.updateMenuAppearance(newAppearance)
            print("AppearanceSettings: Successfully updated menu appearance")
        } catch {
            print("AppearanceSettings: Failed to update menu appearance: \(error)")
        }
    }
}

// MARK: - Import Export View

struct ImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var configManager = ConfigManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up.on.square")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.blue)

                Text("配置管理")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)

                Text("导入或导出您的 MouseQuicker 配置")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Configuration Info
            VStack(spacing: 12) {
                HStack {
                    Text("当前配置信息")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                    Spacer()
                }

                VStack(spacing: 8) {
                    InfoRow(label: "配置版本", value: configManager.currentConfig.version)
                    InfoRow(label: "快捷键数量", value: "\(configManager.currentConfig.shortcutItems.count)")
                    InfoRow(label: "触发延迟", value: "\(String(format: "%.1f", configManager.currentConfig.triggerDuration))秒")
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                )
            }

            // Action Buttons
            VStack(spacing: 12) {
                Button(action: exportConfiguration) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("导出配置")
                    }
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: importConfiguration) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                        Text("导入配置")
                    }
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .padding(.vertical, 8)

                Button(action: resetToDefaults) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("重置为默认设置")
                    }
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Close Button
            HStack {
                Spacer()
                Button("关闭") {
                    dismiss()
                }
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .keyboardShortcut(.escape)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func exportConfiguration() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MouseQuicker_Config.json"
        panel.title = "导出 MouseQuicker 配置"
        panel.message = "选择保存配置文件的位置"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try configManager.exportToFile(url: url)
                alertTitle = "导出成功"
                alertMessage = "配置已成功导出到 \(url.lastPathComponent)"
                showingAlert = true
            } catch {
                alertTitle = "导出失败"
                alertMessage = "导出配置时发生错误：\(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func importConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "导入 MouseQuicker 配置"
        panel.message = "选择要导入的配置文件"

        if panel.runModal() == .OK, let url = panel.urls.first {
            do {
                let _ = try configManager.importFromFile(url: url)
                alertTitle = "导入成功"
                alertMessage = "配置已成功从 \(url.lastPathComponent) 导入"
                showingAlert = true
            } catch {
                alertTitle = "导入失败"
                alertMessage = "导入配置时发生错误：\(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func resetToDefaults() {
        do {
            try configManager.resetToDefaults()
            alertTitle = "重置成功"
            alertMessage = "所有设置已重置为默认值"
            showingAlert = true
        } catch {
            alertTitle = "重置失败"
            alertMessage = "重置设置时发生错误：\(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
        }
    }
}

// MARK: - Add Shortcut View

struct AddShortcutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var configManager = ConfigManager.shared

    @State private var title = ""
    @State private var recordedShortcut: KeyboardShortcut?
    @State private var selectedIcon: IconType? = IconType.sfSymbol("keyboard")
    @State private var selectedExecutionMode: ShortcutExecutionMode = .targetApp
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView

            // Content
            contentView

            // Footer
            footerView
        }
        .padding(20)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("错误", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Text("添加新快捷键")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }

            Divider()
        }
    }

    private var contentView: some View {
        VStack(spacing: 20) {
            // Title input
            VStack(alignment: .leading, spacing: 8) {
                Text("标题")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField("输入快捷键标题", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }

            // Shortcut recorder
            VStack(alignment: .leading, spacing: 8) {
                Text("快捷键")
                    .font(.headline)
                    .foregroundColor(.primary)

                EnhancedShortcutRecorderView(recordedShortcut: $recordedShortcut)
                    .frame(maxWidth: .infinity)
            }

            // Icon picker
            VStack(alignment: .leading, spacing: 8) {
                Text("图标")
                    .font(.headline)
                    .foregroundColor(.primary)

                ModernIconPickerView(selectedIcon: $selectedIcon)
            }

            // Execution mode selector
            VStack(alignment: .leading, spacing: 8) {
                Text("执行模式")
                    .font(.headline)
                    .foregroundColor(.primary)

                ExecutionModeSelector(selectedMode: $selectedExecutionMode)
            }
        }
    }

    private var footerView: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("添加") {
                    addShortcut()
                }
                .keyboardShortcut(.return)
                .disabled(!canAdd)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        recordedShortcut != nil &&
        selectedIcon != nil
    }

    private func addShortcut() {
        guard let shortcut = recordedShortcut,
              let iconType = selectedIcon else {
            showError("请完整填写所有信息")
            return
        }

        // Validate shortcut
        guard shortcut.isValid else {
            showError("快捷键无效，请至少包含一个修饰键")
            return
        }

        // Extract icon name
        let iconName: String
        switch iconType {
        case .sfSymbol(let name):
            iconName = name
        }

        let item = ShortcutItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            shortcut: shortcut,
            iconName: iconName,
            executionMode: selectedExecutionMode
        )

        do {
            try configManager.addShortcutItem(item)
            dismiss()
        } catch {
            showError("添加失败: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Execution Mode Selector

struct ExecutionModeSelector: View {
    @Binding var selectedMode: ShortcutExecutionMode

    var body: some View {
        VStack(spacing: 12) {
            ForEach(ShortcutExecutionMode.allCases, id: \.self) { mode in
                executionModeButton(mode)
            }
        }
    }

    private func executionModeButton(_ mode: ShortcutExecutionMode) -> some View {
        Button(action: {
            selectedMode = mode
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: mode.icon)
                    .font(.title3)
                    .foregroundColor(selectedMode == mode ? .white : .accentColor)
                    .frame(width: 24, height: 24)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(selectedMode == mode ? .white : .primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(selectedMode == mode ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Selection indicator
                if selectedMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedMode == mode ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedMode == mode ? Color.clear : Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
