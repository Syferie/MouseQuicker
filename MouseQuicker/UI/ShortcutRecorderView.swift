//
//  ShortcutRecorderView.swift
//  MouseQuicker
//
//  Created by Assistant on 2025/7/18.
//

import SwiftUI
import AppKit

// MARK: - Shortcut Recorder View

struct ShortcutRecorderView: View {
    @Binding var recordedShortcut: KeyboardShortcut?
    @State private var isRecording = false
    @State private var currentKeys: Set<ModifierKey> = []
    @State private var currentPrimaryKey: KeyCode? = nil
    @State private var recordingText = "点击开始录制"
    @State private var showCurrentShortcut = false

    private let eventMonitor = ShortcutRecorderEventMonitor()

    var body: some View {
        VStack(spacing: 12) {
            // Recording button/display
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
            .onChange(of: recordedShortcut) { newValue in
                print("ShortcutRecorder: recordedShortcut changed to: \(newValue?.displayString ?? "nil")")
                showCurrentShortcut = newValue != nil
                updateRecordingText()
            }

            // Current shortcut display
            if showCurrentShortcut, let shortcut = recordedShortcut {
                VStack(spacing: 4) {
                    Text("当前快捷键:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(shortcut.displayString)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Clear button
            if showCurrentShortcut && recordedShortcut != nil {
                Button("清除") {
                    recordedShortcut = nil
                    showCurrentShortcut = false
                    updateRecordingText()
                }
                .foregroundColor(.red)
                .font(.caption)
            }
        }
        .onAppear {
            print("ShortcutRecorder: View appeared, initial shortcut: \(recordedShortcut?.displayString ?? "nil")")
            showCurrentShortcut = recordedShortcut != nil
            setupEventMonitor()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func setupEventMonitor() {
        print("ShortcutRecorder: Setting up event monitor callbacks")
        eventMonitor.onShortcutRecorded = { shortcut in
            print("ShortcutRecorder: onShortcutRecorded callback triggered with: \(shortcut.displayString)")
            DispatchQueue.main.async {
                print("ShortcutRecorder: Updating UI with shortcut: \(shortcut.displayString)")
                self.recordedShortcut = shortcut
                self.updateRecordingText()
            }
        }

        eventMonitor.onKeysChanged = { modifiers, primaryKey in
            DispatchQueue.main.async {
                print("ShortcutRecorder: Updating UI with keys: \(modifiers), \(primaryKey?.displayName ?? "nil")")
                self.currentKeys = modifiers
                self.currentPrimaryKey = primaryKey
                self.updateRecordingText()
            }
        }
        print("ShortcutRecorder: Event monitor callbacks set up successfully")
    }
    
    private func startRecording() {
        print("ShortcutRecorder: UI startRecording called")

        // Ensure callbacks are set up
        setupEventMonitor()

        isRecording = true
        currentKeys.removeAll()
        currentPrimaryKey = nil
        recordingText = "按下快捷键..."
        eventMonitor.startRecording()
    }
    
    private func stopRecording() {
        print("ShortcutRecorder: UI stopRecording called")
        isRecording = false
        eventMonitor.stopRecording()
        updateRecordingText()
    }
    
    private func updateRecordingText() {
        print("ShortcutRecorder: updateRecordingText called - isRecording: \(isRecording), recordedShortcut: \(recordedShortcut?.displayString ?? "nil")")
        if isRecording {
            if currentKeys.isEmpty && currentPrimaryKey == nil {
                recordingText = "按下快捷键..."
            } else {
                let modifierStrings = currentKeys.sorted { $0.rawValue < $1.rawValue }.map { $0.displayName }
                let keyString = currentPrimaryKey?.displayName ?? ""
                let combined = (modifierStrings + [keyString]).filter { !$0.isEmpty }
                recordingText = combined.joined(separator: "")
            }
        } else {
            if recordedShortcut != nil {
                recordingText = "点击重新录制"
            } else {
                recordingText = "点击开始录制"
            }
        }
        print("ShortcutRecorder: recordingText updated to: \(recordingText)")
    }
}

// MARK: - Shortcut Recorder Event Monitor

class ShortcutRecorderEventMonitor: ObservableObject {
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    
    var onShortcutRecorded: ((KeyboardShortcut) -> Void)?
    var onKeysChanged: ((Set<ModifierKey>, KeyCode?) -> Void)?
    
    private var currentModifiers: Set<ModifierKey> = []
    private var isRecording = false
    
    func startRecording() {
        guard !isRecording else {
            print("ShortcutRecorder: Already recording, ignoring start request")
            return
        }
        print("ShortcutRecorder: Starting recording...")
        isRecording = true
        currentModifiers.removeAll()

        // Monitor local events (when window has focus)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            print("ShortcutRecorder: Local event received - type: \(event.type.rawValue), keyCode: \(event.keyCode)")
            self?.handleEvent(event)
            return nil // Consume the event
        }

        // Monitor global events (when window doesn't have focus)
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            print("ShortcutRecorder: Global event received - type: \(event.type.rawValue), keyCode: \(event.keyCode)")
            self?.handleEvent(event)
        }

        print("ShortcutRecorder: Event monitors set up successfully")
    }
    
    func stopRecording() {
        guard isRecording else {
            print("ShortcutRecorder: Not recording, ignoring stop request")
            return
        }
        print("ShortcutRecorder: Stopping recording...")
        isRecording = false

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
            print("ShortcutRecorder: Local event monitor removed")
        }

        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
            print("ShortcutRecorder: Global event monitor removed")
        }

        currentModifiers.removeAll()
        print("ShortcutRecorder: Recording stopped successfully")
    }
    
    private func handleEvent(_ event: NSEvent) {
        print("ShortcutRecorder: Handling event - type: \(event.type.rawValue), keyCode: \(event.keyCode), modifiers: \(event.modifierFlags)")
        switch event.type {
        case .flagsChanged:
            handleModifierChange(event)
        case .keyDown:
            handleKeyDown(event)
        default:
            print("ShortcutRecorder: Unhandled event type: \(event.type.rawValue)")
            break
        }
    }
    
    private func handleModifierChange(_ event: NSEvent) {
        let newModifiers = extractModifiers(from: event.modifierFlags)
        print("ShortcutRecorder: Modifier change - old: \(currentModifiers), new: \(newModifiers)")
        currentModifiers = newModifiers
        onKeysChanged?(currentModifiers, nil)
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        print("ShortcutRecorder: Key down - keyCode: \(event.keyCode)")
        guard let keyCode = KeyCode.from(event.keyCode) else {
            print("ShortcutRecorder: Unknown key code: \(event.keyCode)")
            return
        }

        // Update current state
        let modifiers = extractModifiers(from: event.modifierFlags)
        currentModifiers = modifiers
        print("ShortcutRecorder: Key pressed - \(keyCode.displayName) with modifiers: \(modifiers)")

        // Create shortcut
        let shortcut = KeyboardShortcut(primaryKey: keyCode, modifiers: modifiers)
        print("ShortcutRecorder: Created shortcut - \(shortcut.displayString), isValid: \(shortcut.isValid)")

        // Validate shortcut (require at least one modifier for global shortcuts)
        if shortcut.isValid {
            print("ShortcutRecorder: Recording valid shortcut: \(shortcut.displayString)")
            print("ShortcutRecorder: Calling onShortcutRecorded callback...")

            // Stop recording first to prevent further events
            stopRecording()

            // Then call the callback
            print("ShortcutRecorder: About to call callback, onShortcutRecorded is \(onShortcutRecorded != nil ? "set" : "nil")")
            onShortcutRecorded?(shortcut)
            print("ShortcutRecorder: Callback called")
        } else {
            print("ShortcutRecorder: Invalid shortcut (no modifiers), showing key press")
            // Still show the key being pressed
            onKeysChanged?(modifiers, keyCode)
        }
    }
    
    private func extractModifiers(from flags: NSEvent.ModifierFlags) -> Set<ModifierKey> {
        var modifiers: Set<ModifierKey> = []
        
        if flags.contains(.command) {
            modifiers.insert(.command)
        }
        if flags.contains(.option) {
            modifiers.insert(.option)
        }
        if flags.contains(.control) {
            modifiers.insert(.control)
        }
        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }
        if flags.contains(.function) {
            modifiers.insert(.function)
        }
        
        return modifiers
    }
    
    deinit {
        stopRecording()
    }
}

// MARK: - KeyCode Extension

extension KeyCode {
    static func from(_ keyCode: UInt16) -> KeyCode? {
        // Map common key codes to KeyCode enum
        switch keyCode {
        case 0: return .a
        case 11: return .b
        case 8: return .c
        case 2: return .d
        case 14: return .e
        case 3: return .f
        case 5: return .g
        case 4: return .h
        case 34: return .i
        case 38: return .j
        case 40: return .k
        case 37: return .l
        case 46: return .m
        case 45: return .n
        case 31: return .o
        case 35: return .p
        case 12: return .q
        case 15: return .r
        case 1: return .s
        case 17: return .t
        case 32: return .u
        case 9: return .v
        case 13: return .w
        case 7: return .x
        case 16: return .y
        case 6: return .z
        case 29: return .digit0
        case 18: return .digit1
        case 19: return .digit2
        case 20: return .digit3
        case 21: return .digit4
        case 23: return .digit5
        case 22: return .digit6
        case 26: return .digit7
        case 28: return .digit8
        case 25: return .digit9
        case 49: return .space
        case 48: return .tab
        case 36: return .enter
        case 53: return .escape
        case 51: return .delete
        case 123: return .leftArrow
        case 124: return .rightArrow
        case 126: return .upArrow
        case 125: return .downArrow
        default: return nil
        }
    }
}
