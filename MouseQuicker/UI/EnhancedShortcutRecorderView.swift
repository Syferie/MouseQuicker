//
//  EnhancedShortcutRecorderView.swift
//  MouseQuicker
//
//  Created by Assistant on 2025/7/18.
//

import SwiftUI
import AppKit

// MARK: - Enhanced Shortcut Recorder View

struct EnhancedShortcutRecorderView: View {
    @Binding var recordedShortcut: KeyboardShortcut?
    @State private var inputMode: InputMode = .recording
    @State private var isRecording = false
    @State private var recordingText = "点击开始录制"
    @State private var showCurrentShortcut = false
    
    // Manual input states
    @State private var selectedModifiers: Set<ModifierKey> = []
    @State private var selectedPrimaryKey: KeyCode? = nil
    @State private var showingKeyPicker = false
    
    // Conflict detection
    @State private var hasConflict = false
    @State private var conflictMessage = ""
    
    private let eventMonitor = ShortcutRecorderEventMonitor()
    
    enum InputMode: String, CaseIterable {
        case recording = "录制模式"
        case manual = "手动输入"
        
        var icon: String {
            switch self {
            case .recording: return "keyboard"
            case .manual: return "hand.point.up"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Mode selector
            modeSelector
            
            // Input area based on mode
            Group {
                if inputMode == .recording {
                    recordingInputView
                } else {
                    manualInputView
                }
            }

            // Conflict warning
            if hasConflict {
                conflictWarningView
            }

            // Action buttons (only for manual input mode)
            if inputMode == .manual {
                actionButtonsView
            }
        }
        .onAppear {
            setupEventMonitor()
            updateFromCurrentShortcut()
        }
        .onChange(of: recordedShortcut) { _, newValue in
            showCurrentShortcut = newValue != nil
            updateFromCurrentShortcut()
            checkForConflicts()
        }
    }
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(InputMode.allCases, id: \.self) { mode in
                Button(action: {
                    switchToMode(mode)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.caption)
                        Text(mode.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        inputMode == mode ? 
                        Color.accentColor : Color.clear
                    )
                    .foregroundColor(
                        inputMode == mode ? 
                        .white : .primary
                    )
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Recording Input View
    
    private var recordingInputView: some View {
        VStack(spacing: 12) {
            // 如果已经录制了快捷键，显示录制结果
            if let shortcut = recordedShortcut, !isRecording {
                recordedShortcutDisplayView(shortcut)
            } else {
                // 录制按钮
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "keyboard")
                            .foregroundColor(isRecording ? .red : .accentColor)

                        Text(recordingText)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(isRecording ? .red : .primary)
                    }
                    .frame(minWidth: 200, minHeight: 40)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isRecording ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isRecording ? Color.red : Color.accentColor, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                if isRecording {
                    Text("按下快捷键组合，或点击停止取消录制")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Recorded Shortcut Display View

    private func recordedShortcutDisplayView(_ shortcut: KeyboardShortcut) -> some View {
        VStack(spacing: 12) {
            // 显示录制的快捷键
            HStack {
                Image(systemName: "keyboard")
                    .foregroundColor(.accentColor)

                Text(shortcut.displayString)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Quick edit button
                Button(action: {
                    quickEditShortcut(shortcut)
                }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .help("快速调整")
            }
            .frame(minWidth: 200, minHeight: 40)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
            )

            // 操作按钮
            HStack(spacing: 12) {
                Button("清除") {
                    clearShortcut()
                }
                .buttonStyle(.bordered)

                Button("重新录制") {
                    startRecording()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Manual Input View
    
    private var manualInputView: some View {
        VStack(spacing: 12) {
            // Modifier keys selection
            VStack(alignment: .leading, spacing: 8) {
                Text("修饰键")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(ModifierKey.allCases, id: \.self) { modifier in
                        modifierKeyButton(modifier)
                    }
                }
            }
            
            // Primary key selection
            VStack(alignment: .leading, spacing: 8) {
                Text("主键")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingKeyPicker = true
                }) {
                    HStack {
                        Text(selectedPrimaryKey?.displayName ?? "选择按键")
                            .font(.system(.body, design: .monospaced))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showingKeyPicker) {
                    KeyPickerView(selectedKey: $selectedPrimaryKey)
                }
            }
            
            // Apply button
            if !selectedModifiers.isEmpty && selectedPrimaryKey != nil {
                Button("应用快捷键") {
                    applyManualShortcut()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Views
    
    private func modifierKeyButton(_ modifier: ModifierKey) -> some View {
        Button(action: {
            if selectedModifiers.contains(modifier) {
                selectedModifiers.remove(modifier)
            } else {
                selectedModifiers.insert(modifier)
            }
        }) {
            Text(modifier.displayName)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    selectedModifiers.contains(modifier) ? 
                    Color.accentColor : Color(NSColor.controlBackgroundColor)
                )
                .foregroundColor(
                    selectedModifiers.contains(modifier) ? 
                    .white : .primary
                )
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    

    
    private var conflictWarningView: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(conflictMessage)
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            if showCurrentShortcut && recordedShortcut != nil {
                Button("清除") {
                    clearShortcut()
                }
                .buttonStyle(.bordered)
            }
            
            if inputMode == .recording && !isRecording {
                Button("重新录制") {
                    startRecording()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Actions
    
    private func switchToMode(_ mode: InputMode) {
        if isRecording {
            stopRecording()
        }
        inputMode = mode
        
        if mode == .manual {
            updateFromCurrentShortcut()
        }
    }
    
    private func updateFromCurrentShortcut() {
        if let shortcut = recordedShortcut {
            selectedModifiers = shortcut.modifiers
            selectedPrimaryKey = shortcut.primaryKey
        }
    }
    
    private func applyManualShortcut() {
        guard let primaryKey = selectedPrimaryKey else { return }
        
        let shortcut = KeyboardShortcut(primaryKey: primaryKey, modifiers: selectedModifiers)
        recordedShortcut = shortcut
    }
    
    private func quickEditShortcut(_ shortcut: KeyboardShortcut) {
        selectedModifiers = shortcut.modifiers
        selectedPrimaryKey = shortcut.primaryKey
        inputMode = .manual
    }
    
    private func clearShortcut() {
        recordedShortcut = nil
        selectedModifiers.removeAll()
        selectedPrimaryKey = nil
        showCurrentShortcut = false
        hasConflict = false
        updateRecordingText()  // 更新录制文本显示
    }
    
    private func checkForConflicts() {
        // TODO: 实现冲突检测逻辑
        // 这里可以检查系统快捷键冲突
        hasConflict = false
        conflictMessage = ""
    }
    
    // MARK: - Recording Methods
    
    private func setupEventMonitor() {
        print("EnhancedShortcutRecorder: Setting up event monitor callbacks")
        eventMonitor.onShortcutRecorded = { shortcut in
            print("EnhancedShortcutRecorder: onShortcutRecorded callback triggered with: \(shortcut.displayString)")
            DispatchQueue.main.async {
                print("EnhancedShortcutRecorder: Updating UI with shortcut: \(shortcut.displayString)")
                self.recordedShortcut = shortcut
                self.isRecording = false  // 自动停止录制状态
                self.updateRecordingText()
            }
        }

        eventMonitor.onKeysChanged = { modifiers, keyCode in
            DispatchQueue.main.async {
                let modifierStrings = modifiers.sorted { $0.rawValue < $1.rawValue }.map { $0.displayName }
                let keyString = keyCode?.displayName ?? ""
                let displayString = (modifierStrings + [keyString]).joined(separator: "")
                self.recordingText = displayString.isEmpty ? "按下快捷键..." : displayString
            }
        }
        print("EnhancedShortcutRecorder: Event monitor callbacks set up successfully")
    }
    
    private func startRecording() {
        print("EnhancedShortcutRecorder: UI startRecording called")

        // Ensure callbacks are set up before starting
        setupEventMonitor()

        isRecording = true
        recordingText = "按下快捷键..."
        print("EnhancedShortcutRecorder: About to start event monitor recording")
        eventMonitor.startRecording()
        print("EnhancedShortcutRecorder: Event monitor recording started")
    }
    
    private func stopRecording() {
        isRecording = false
        eventMonitor.stopRecording()
        updateRecordingText()
    }
    
    private func updateRecordingText() {
        if let shortcut = recordedShortcut {
            recordingText = shortcut.displayString
        } else {
            recordingText = "点击开始录制"
        }
    }
}
