//
//  ApplicationSelectorView.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/25.
//

import SwiftUI
import AppKit

/// A view for selecting applications in shortcut scope configuration
struct ApplicationSelectorView: View {
    
    // MARK: - Properties
    
    @Binding var applicationScope: ApplicationScope
    @Environment(\.dismiss) private var dismiss
    @StateObject private var applicationManager = ApplicationManager.shared
    
    @State private var searchText = ""
    @State private var selectedApplications: Set<String> = []
    @State private var selectedMode: ApplicationScopeMode = .allApplications
    
    // MARK: - Computed Properties
    
    private var filteredApplications: [ApplicationInfo] {
        if searchText.isEmpty {
            return applicationManager.runningApplications
        } else {
            return applicationManager.searchApplications(query: searchText)
        }
    }
    
    private var isValidSelection: Bool {
        switch selectedMode {
        case .allApplications:
            return true
        case .specificApplications, .excludeApplications:
            return !selectedApplications.isEmpty
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            contentView
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Image(systemName: "app.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("配置生效范围")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            
            // Mode Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("快捷键显示范围")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("决定此快捷键在哪些应用中显示在菜单中")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("生效范围", selection: $selectedMode) {
                    ForEach(ApplicationScopeMode.allCases, id: \.self) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedMode) { _ in
                    if selectedMode == .allApplications {
                        selectedApplications.removeAll()
                    }
                }
                
                Text(selectedMode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 0) {
            if selectedMode != .allApplications {
                // Search Bar
                searchBarView
                
                Divider()
                
                // Application List
                applicationListView
            } else {
                // All Applications Mode Info
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundColor(.blue.opacity(0.6))
                    
                    Text("快捷键将在所有应用中生效")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("无需选择特定应用")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
        }
    }
    
    // MARK: - Search Bar View
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索应用...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Application List View
    
    private var applicationListView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredApplications) { app in
                    ApplicationRowView(
                        application: app,
                        isSelected: selectedApplications.contains(app.id),
                        onToggle: { toggleApplication(app) }
                    )
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Footer View
    
    private var footerView: some View {
        HStack {
            // Selection Info
            if selectedMode != .allApplications && !selectedApplications.isEmpty {
                Text("已选择 \(selectedApplications.count) 个应用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Button("确定") {
                    saveSelection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidSelection)
            }
        }
        .padding(20)
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        selectedMode = applicationScope.mode
        selectedApplications = Set(applicationScope.applications.map { $0.id })
    }
    
    private func toggleApplication(_ app: ApplicationInfo) {
        if selectedApplications.contains(app.id) {
            selectedApplications.remove(app.id)
        } else {
            selectedApplications.insert(app.id)
        }
    }
    
    private func saveSelection() {
        let selectedApps = applicationManager.runningApplications.filter { app in
            selectedApplications.contains(app.id)
        }
        
        applicationScope = ApplicationScope(
            mode: selectedMode,
            applications: selectedApps
        )
        
        dismiss()
    }
}

// MARK: - Application Row View

struct ApplicationRowView: View {
    let application: ApplicationInfo
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            if let icon = application.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
            
            // App Info
            VStack(alignment: .leading, spacing: 2) {
                Text(application.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(application.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Selection Indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isSelected ? .blue : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    ApplicationSelectorView(
        applicationScope: .constant(ApplicationScope.default)
    )
}
