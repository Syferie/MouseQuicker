//
//  IconPickerView.swift
//  MouseQuicker
//
//  Created by Assistant on 2025/7/18.
//

import SwiftUI
import AppKit

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Binding var selectedIcon: IconType?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: IconCategory = .system
    @State private var searchText = ""
    @State private var icons: [IconType] = []

    private let iconManager = IconManager.shared

    // 内存管理
    @State private var isViewActive = true
    @State private var hasCleanedUp = false // 防止重复清理
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            HStack(spacing: 0) {
                // Sidebar
                sidebarView
                
                Divider()
                
                // Main content
                mainContentView
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            loadIcons()
        }
        .onChange(of: selectedCategory) { _ in
            loadIcons()
        }
        .onChange(of: searchText) { _ in
            loadIcons()
        }
        .onAppear {
            isViewActive = true
        }
        .onDisappear {
            isViewActive = false
            // 清理内存
            cleanupMemory()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("选择图标")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("确定") {
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(selectedIcon == nil)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索图标...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding()
    }
    
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("分类")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(IconCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(width: 150)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func categoryButton(_ category: IconCategory) -> some View {
        HStack {
            Text(category.rawValue)
                .font(.system(size: 13))
                .foregroundColor(selectedCategory == category ? .primary : .secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            selectedCategory == category ?
            Color.accentColor.opacity(0.2) :
            Color.clear
        )
        .cornerRadius(6)
        .contentShape(Rectangle()) // 使整个区域可点击
        .onTapGesture {
            selectedCategory = category
        }
        .animation(.easeInOut(duration: 0.15), value: selectedCategory)
    }
    
    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category title and count
            HStack {
                Text(searchText.isEmpty ? selectedCategory.rawValue : "搜索结果")
                    .font(.headline)
                
                Text("(\(icons.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Icons grid
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(icons.indices, id: \.self) { index in
                        iconButton(icons[index])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func iconButton(_ iconType: IconType) -> some View {
        Button(action: {
            selectedIcon = iconType
        }) {
            VStack(spacing: 6) {
                // Icon preview with better error handling
                ZStack {
                    if let nsImage = iconManager.getIcon(type: iconType, size: 28) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .foregroundColor(.primary)
                    } else {
                        // Better fallback for missing icons
                        Image(systemName: "questionmark.square.dashed")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                    }
                }

                // Icon name with smart abbreviation
                Text(smartAbbreviate(iconName(for: iconType)))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 80, alignment: .center)
                    .minimumScaleFactor(0.9)
            }
            .frame(width: 80, height: 75) // Larger frame for better spacing
            .padding(.vertical, 6)
            .background(
                selectedIcon == iconType ?
                Color.accentColor.opacity(0.2) :
                Color.clear
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedIcon == iconType ?
                        Color.accentColor :
                        Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .help(iconName(for: iconType)) // 完整名称显示在工具提示中
    }
    
    private func iconName(for iconType: IconType) -> String {
        switch iconType {
        case .sfSymbol(let name):
            return name
        }
    }

    // 智能缩写长图标名称
    private func smartAbbreviate(_ name: String) -> String {
        var result = name

        // 1. 首先移除常见的修饰性后缀（图标变体）
        let modifierSuffixes = [
            ".circle.fill",    // 填充圆形背景
            ".square.fill",    // 填充方形背景
            ".rectangle.fill", // 填充矩形背景
            ".badge.fill",     // 填充徽章
            ".badge.plus",     // 加号徽章
            ".badge.minus",    // 减号徽章
            ".slash.fill",     // 填充斜线版本
            ".fill",           // 填充版本
            ".circle",         // 圆形背景
            ".square",         // 方形背景
            ".rectangle",      // 矩形背景
            ".badge",          // 徽章版本
            ".slash",          // 斜线版本
            ".dashed",         // 虚线版本
            ".dotted"          // 点线版本
        ]

        // 移除修饰性后缀（按长度排序，先移除长的）
        for suffix in modifierSuffixes.sorted(by: { $0.count > $1.count }) {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
                break // 只移除一个后缀
            }
        }

        // 2. 如果移除后缀后名称已经足够短，直接返回（提高阈值）
        if result.count <= 16 {
            return result
        }

        // 3. 只对确实很长的名称进行必要的缩写
        // 优先处理复合词和常见的长词
        let necessaryAbbreviations: [String: String] = [
            "magnifyingglass": "search",
            "externaldrive": "ext.drive",
            "internaldrive": "int.drive",
            "opticaldiscdrive": "optical",
            "desktopcomputer": "desktop",
            "laptopcomputer": "laptop",
            "wrench.and.screwdriver": "tools",
            "left.and.right": "l&r",
            "up.and.down": "u&d",
            "forwardslash": "/"
        ]

        // 应用必要的缩写
        for (full, abbrev) in necessaryAbbreviations {
            result = result.replacingOccurrences(of: full, with: abbrev)
        }

        // 4. 如果仍然太长，进行结构化处理
        if result.count > 18 {
            let parts = result.components(separatedBy: ".")
            if parts.count > 3 {
                // 保留第一部分和最后一部分，中间用省略号
                let firstPart = parts[0]
                let lastPart = parts.last!
                result = "\(firstPart)...\(lastPart)"
            } else if parts.count == 3 {
                // 三部分的情况，保留前两部分
                result = "\(parts[0]).\(parts[1])"
            } else if result.count > 22 {
                // 单个长词，截断并添加省略号
                let index = result.index(result.startIndex, offsetBy: 19)
                result = String(result[..<index]) + "..."
            }
        }

        return result
    }
    
    private func loadIcons() {
        // 在后台线程加载图标，避免阻塞UI
        DispatchQueue.global(qos: .userInitiated).async {
            let newIcons: [IconType]
            if self.searchText.isEmpty {
                newIcons = self.iconManager.getAllIcons(category: self.selectedCategory)
            } else {
                newIcons = self.iconManager.searchIcons(query: self.searchText)
            }

            // 回到主线程更新UI
            DispatchQueue.main.async {
                // 检查视图是否还活跃
                if self.isViewActive {
                    self.icons = newIcons
                }
            }
        }
    }

    // MARK: - Memory Management

    /// 清理内存，释放图标数据（图标选择器是真正的性能瓶颈）
    private func cleanupMemory() {
        // 防止重复清理
        guard !hasCleanedUp else {
            print("IconPickerView: Cleanup already performed, skipping")
            return
        }
        hasCleanedUp = true

        print("IconPickerView: Starting memory cleanup")

        // 立即清空图标数组，这是最重要的内存释放
        icons.removeAll()
        searchText = ""

        // 延迟清理缓存，给视图销毁留出时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 在后台线程清理缓存
            DispatchQueue.global(qos: .utility).async {
                print("IconPickerView: Clearing icon cache")
                self.iconManager.clearCache()

                print("IconPickerView: Clearing category cache")
                IconCategoryCache.shared.clearCache()

                DispatchQueue.main.async {
                    print("IconPickerView: Memory cleanup completed")
                }
            }
        }
    }
}

// MARK: - Icon Picker Button

struct IconPickerButton: View {
    @Binding var selectedIcon: IconType?
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack {
                if let iconType = selectedIcon,
                   let nsImage = IconManager.shared.getIcon(type: iconType, size: 16) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "photo")
                        .frame(width: 16, height: 16)
                }
                
                Text(selectedIcon != nil ? "更改图标" : "选择图标")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .sheet(isPresented: $showingPicker) {
            IconPickerView(selectedIcon: $selectedIcon)
        }
    }
}

// MARK: - Preview

#Preview {
    IconPickerView(selectedIcon: .constant(nil))
}
