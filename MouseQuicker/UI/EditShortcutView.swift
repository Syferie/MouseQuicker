//
//  EditShortcutView.swift
//  MouseQuicker
//
//  Created by Assistant on 2025/7/18.
//

import SwiftUI

// MARK: - Edit Shortcut View

struct EditShortcutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var configManager = ConfigManager.shared
    
    let shortcutItem: ShortcutItem
    
    @State private var title: String
    @State private var recordedShortcut: KeyboardShortcut?
    @State private var selectedIcon: IconType?
    @State private var selectedExecutionMode: ShortcutExecutionMode
    @State private var applicationScope: ApplicationScope
    @State private var showingApplicationSelector = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(shortcutItem: ShortcutItem) {
        self.shortcutItem = shortcutItem
        self._title = State(initialValue: shortcutItem.title)
        self._recordedShortcut = State(initialValue: shortcutItem.shortcut)
        self._selectedIcon = State(initialValue: IconType.sfSymbol(shortcutItem.iconName))
        self._selectedExecutionMode = State(initialValue: shortcutItem.executionMode)
        self._applicationScope = State(initialValue: shortcutItem.applicationScope)
    }
    
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
        .sheet(isPresented: $showingApplicationSelector) {
            ApplicationSelectorView(applicationScope: $applicationScope)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Text("编辑快捷键")
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

            // Application scope selector
            VStack(alignment: .leading, spacing: 8) {
                Text("生效范围")
                    .font(.headline)
                    .foregroundColor(.primary)

                ApplicationScopeSelector(
                    applicationScope: $applicationScope,
                    showingApplicationSelector: $showingApplicationSelector
                )
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

                Button("保存") {
                    saveChanges()
                }
                .keyboardShortcut(.return)
                .disabled(!canSave)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        recordedShortcut != nil &&
        selectedIcon != nil
    }
    
    private func saveChanges() {
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
        
        // Create updated item
        let updatedItem = shortcutItem.with(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            shortcut: shortcut,
            iconName: iconName,
            executionMode: selectedExecutionMode,
            applicationScope: applicationScope
        )
        
        // Save to config
        do {
            try configManager.updateShortcutItem(updatedItem)
            dismiss()
        } catch {
            showError("保存失败: \(error.localizedDescription)")
        }
    }
    

    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Modern Icon Picker View

struct ModernIconPickerView: View {
    @Binding var selectedIcon: IconType?
    @State private var showingIconPicker = false

    var body: some View {
        Button(action: {
            showingIconPicker = true
        }) {
            HStack(spacing: 12) {
                // Icon preview with background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)

                    if let iconType = selectedIcon,
                       let nsImage = IconManager.shared.getIcon(type: iconType, size: 20) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedIcon != nil ? "已选择图标" : "选择图标")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("点击更换图标")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct EditShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        EditShortcutView(shortcutItem: ShortcutItem(
            title: "复制",
            shortcut: KeyboardShortcut(primaryKey: .c, modifiers: [.command]),
            iconName: "doc.on.doc"
        ))
    }
}
#endif
