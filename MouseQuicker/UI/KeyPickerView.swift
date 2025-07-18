//
//  KeyPickerView.swift
//  MouseQuicker
//
//  Created by Assistant on 2025/7/18.
//

import SwiftUI
import AppKit

// MARK: - Key Picker View

struct KeyPickerView: View {
    @Binding var selectedKey: KeyCode?
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: KeyCategory = .letters
    
    enum KeyCategory: String, CaseIterable {
        case letters = "字母"
        case numbers = "数字"
        case function = "功能键"
        case arrows = "方向键"
        case special = "特殊键"
        
        var keys: [KeyCode] {
            switch self {
            case .letters:
                return [.a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m, .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z]
            case .numbers:
                return [.digit0, .digit1, .digit2, .digit3, .digit4, .digit5, .digit6, .digit7, .digit8, .digit9]
            case .function:
                return [.f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12]
            case .arrows:
                return [.upArrow, .downArrow, .leftArrow, .rightArrow]
            case .special:
                return [.space, .tab, .enter, .escape, .delete, .backspace, .home, .end, .pageUp, .pageDown]
            }
        }
    }
    
    private var filteredKeys: [KeyCode] {
        let categoryKeys = selectedCategory.keys
        
        if searchText.isEmpty {
            return categoryKeys
        } else {
            return categoryKeys.filter { key in
                key.displayName.localizedCaseInsensitiveContains(searchText) ||
                key.keyDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            HStack(spacing: 0) {
                // Category sidebar
                categoryView
                
                Divider()
                
                // Key grid
                keyGridView
            }
        }
        .frame(width: 400, height: 300)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("选择按键")
                    .font(.headline)
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索按键...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding()
    }
    
    // MARK: - Category View
    
    private var categoryView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("分类")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            ForEach(KeyCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack {
                        Text(category.rawValue)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(category.keys.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        selectedCategory == category ? 
                        Color.accentColor.opacity(0.2) : Color.clear
                    )
                    .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(width: 100)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
    
    // MARK: - Key Grid View
    
    private var keyGridView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category title and count
            HStack {
                Text(searchText.isEmpty ? selectedCategory.rawValue : "搜索结果")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("(\(filteredKeys.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Keys grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(filteredKeys, id: \.self) { key in
                        keyButton(key)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Key Button
    
    private func keyButton(_ key: KeyCode) -> some View {
        Button(action: {
            selectedKey = key
            dismiss()
        }) {
            VStack(spacing: 4) {
                Text(key.displayName)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(key.keyDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                selectedKey == key ? 
                Color.accentColor : Color(NSColor.controlBackgroundColor)
            )
            .foregroundColor(
                selectedKey == key ? 
                .white : .primary
            )
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        selectedKey == key ? 
                        Color.accentColor : Color.clear, 
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - KeyCode Extensions

extension KeyCode {
    /// Description for display purposes
    var keyDescription: String {
        switch self {
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .h: return "H"
        case .i: return "I"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .m: return "M"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .digit0: return "0"
        case .digit1: return "1"
        case .digit2: return "2"
        case .digit3: return "3"
        case .digit4: return "4"
        case .digit5: return "5"
        case .digit6: return "6"
        case .digit7: return "7"
        case .digit8: return "8"
        case .digit9: return "9"
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        case .upArrow: return "↑"
        case .downArrow: return "↓"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .space: return "Space"
        case .tab: return "Tab"
        case .enter: return "Enter"
        case .escape: return "Esc"
        case .delete: return "Delete"
        case .backspace: return "Backspace"
        case .home: return "Home"
        case .end: return "End"
        case .pageUp: return "PgUp"
        case .pageDown: return "PgDn"
        default: return rawValue.uppercased()
        }
    }
}

// MARK: - Preview

#Preview {
    KeyPickerView(selectedKey: .constant(.a))
}
