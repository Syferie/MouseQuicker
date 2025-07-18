//
//  IconSystem.swift
//  MouseQuicker
//
//  Created by Assistant on 2025/7/18.
//

import Foundation
import AppKit

// MARK: - Icon Types

enum IconType {
    case sfSymbol(String)           // SF Symbols only for now
}

// MARK: - Icon Categories

enum IconCategory: String, CaseIterable {
    case system = "系统"
    case applications = "应用程序"
    case files = "文件"
    case media = "媒体"
    case communication = "通讯"
    case navigation = "导航"
    case editing = "编辑"
    case development = "开发"
    case custom = "自定义"
    
    // 使用懒加载减少内存占用
    var sfSymbols: [String] {
        return IconCategoryCache.shared.getSymbols(for: self)
    }

    // 内部实现，避免重复创建大数组
    fileprivate var _sfSymbols: [String] {
        switch self {
        case .system:
            return [
                "gear", "gearshape", "gearshape.fill", "power", "restart", "sleep", "lock", "lock.fill",
                "unlock", "unlock.fill", "shield", "shield.fill", "checkmark.shield", "checkmark.shield.fill",
                "exclamationmark.shield", "exclamationmark.shield.fill", "key", "key.fill", "wifi", "wifi.slash",
                "antenna.radiowaves.left.and.right", "battery.100", "battery.75", "battery.50", "battery.25",
                "battery.0", "bolt", "bolt.fill", "bolt.circle", "bolt.circle.fill", "cpu", "memorychip",
                "internaldrive", "externaldrive", "opticaldiscdrive", "tv", "tv.fill", "display", "desktopcomputer",
                "laptopcomputer", "iphone", "ipad", "applewatch", "airpods", "homepod", "speaker", "hifispeaker",
                "headphones", "earpods", "keyboard", "mouse", "trackpad", "printer", "scanner", "faxmachine"
            ]
        case .applications:
            return [
                "app", "app.fill", "app.badge", "app.badge.fill", "folder", "folder.fill", "folder.badge",
                "folder.badge.fill", "trash", "trash.fill", "terminal", "terminal.fill", "safari", "safari.fill",
                "finder", "gearshape", "bag", "video", "message", "mail", "calendar", "photo",
                "camera", "music.note", "tv", "headphones", "book", "newspaper", "chart.line.uptrend.xyaxis", "cloud.rain", "clock", "calculator",
                "person.crop.circle", "list.bullet", "note.text", "rectangle.on.rectangle", "key", "function", "doc.text",
                "paintbrush", "hammer", "wrench", "gamecontroller", "printer", "scanner",
                "wifi", "bluetooth", "airplane", "car", "house", "building", "globe"
            ]
        case .files:
            return [
                "doc", "doc.fill", "doc.text", "doc.text.fill", "doc.richtext", "doc.richtext.fill", "doc.plaintext",
                "doc.plaintext.fill", "doc.append", "doc.append.fill", "doc.badge.plus", "doc.badge.gearshape",
                "doc.badge.ellipsis", "doc.circle", "doc.circle.fill", "folder", "folder.fill", "folder.circle",
                "folder.circle.fill", "folder.badge.plus", "folder.badge.minus", "folder.badge.questionmark",
                "folder.badge.gearshape", "archivebox", "archivebox.fill", "archivebox.circle", "archivebox.circle.fill",
                "externaldrive", "externaldrive.fill", "externaldrive.connected.to.line.below", "internaldrive",
                "internaldrive.fill", "opticaldiscdrive", "opticaldiscdrive.fill", "server.rack", "xserve",
                "paperclip", "paperclip.circle", "paperclip.circle.fill", "link", "link.circle", "link.circle.fill",
                "plus", "minus", "multiply", "divide", "equal", "percent", "number", "textformat", "textformat.123",
                "textformat.abc", "textformat.abc.dottedunderline", "bold", "italic", "underline", "strikethrough"
            ]
        case .media:
            return [
                "play", "play.fill", "play.circle", "play.circle.fill", "play.rectangle", "play.rectangle.fill",
                "pause", "pause.fill", "pause.circle", "pause.circle.fill", "pause.rectangle", "pause.rectangle.fill",
                "stop", "stop.fill", "stop.circle", "stop.circle.fill", "record.circle", "record.circle.fill",
                "playpause", "playpause.fill", "backward", "backward.fill", "forward", "forward.fill",
                "backward.end", "backward.end.fill", "forward.end", "forward.end.fill", "backward.frame",
                "backward.frame.fill", "forward.frame", "forward.frame.fill", "eject", "eject.fill",
                "eject.circle", "eject.circle.fill", "memories", "memories.badge.plus", "memories.badge.minus",
                "shuffle", "shuffle.circle", "shuffle.circle.fill", "repeat", "repeat.1", "repeat.circle",
                "repeat.circle.fill", "infinity", "infinity.circle", "infinity.circle.fill", "megaphone",
                "megaphone.fill", "speaker", "speaker.fill", "speaker.slash", "speaker.slash.fill",
                "speaker.wave.1", "speaker.wave.1.fill", "speaker.wave.2", "speaker.wave.2.fill",
                "speaker.wave.3", "speaker.wave.3.fill", "speaker.badge.plus", "speaker.badge.minus"
            ]
        case .communication:
            return [
                "message", "message.fill", "message.circle", "message.circle.fill", "message.badge",
                "message.badge.fill", "bubble.left", "bubble.left.fill", "bubble.right", "bubble.right.fill",
                "bubble.middle.bottom", "bubble.middle.bottom.fill", "bubble.middle.top", "bubble.middle.top.fill",
                "quote.bubble", "quote.bubble.fill", "text.bubble", "text.bubble.fill", "captions.bubble",
                "captions.bubble.fill", "plus.bubble", "plus.bubble.fill", "ellipsis.bubble", "ellipsis.bubble.fill",
                "phone", "phone.fill", "phone.circle", "phone.circle.fill", "phone.badge.plus", "phone.badge.minus",
                "phone.connection", "phone.arrow.up.right", "phone.arrow.down.left", "phone.arrow.right",
                "video", "video.fill", "video.circle", "video.circle.fill", "video.slash", "video.slash.fill",
                "video.badge.plus", "video.badge.minus", "arrow.up.message", "arrow.up.message.fill",
                "mail", "mail.fill", "mail.stack", "mail.stack.fill", "mail.and.text.magnifyingglass",
                "envelope", "envelope.fill", "envelope.circle", "envelope.circle.fill", "envelope.arrow.triangle.branch",
                "envelope.badge", "envelope.badge.fill", "envelope.open", "envelope.open.fill", "person", "person.fill",
                "person.circle", "person.circle.fill", "person.badge.plus", "person.badge.minus", "person.2", "person.2.fill"
            ]
        case .navigation:
            return [
                "arrow.up", "arrow.down", "arrow.left", "arrow.right", "arrow.up.left", "arrow.up.right",
                "arrow.down.left", "arrow.down.right", "arrow.up.circle", "arrow.up.circle.fill",
                "arrow.down.circle", "arrow.down.circle.fill", "arrow.left.circle", "arrow.left.circle.fill",
                "arrow.right.circle", "arrow.right.circle.fill", "arrow.up.square", "arrow.up.square.fill",
                "arrow.down.square", "arrow.down.square.fill", "arrow.left.square", "arrow.left.square.fill",
                "arrow.right.square", "arrow.right.square.fill", "chevron.up", "chevron.down", "chevron.left",
                "chevron.right", "chevron.up.circle", "chevron.up.circle.fill", "chevron.down.circle",
                "chevron.down.circle.fill", "chevron.left.circle", "chevron.left.circle.fill", "chevron.right.circle",
                "chevron.right.circle.fill", "chevron.up.square", "chevron.up.square.fill", "chevron.down.square",
                "chevron.down.square.fill", "chevron.left.square", "chevron.left.square.fill", "chevron.right.square",
                "chevron.right.square.fill", "house", "house.fill", "house.circle", "house.circle.fill",
                "building", "building.fill", "building.2", "building.2.fill", "building.columns", "building.columns.fill",
                "magnifyingglass", "magnifyingglass.circle", "magnifyingglass.circle.fill", "location", "location.fill",
                "location.circle", "location.circle.fill", "location.north", "location.north.fill", "map", "map.fill",
                "mappin", "mappin.circle", "mappin.circle.fill", "mappin.and.ellipse", "globe", "globe.americas",
                "globe.americas.fill", "globe.europe.africa", "globe.europe.africa.fill", "globe.asia.australia",
                "globe.asia.australia.fill", "network", "wifi", "wifi.circle", "wifi.circle.fill"
            ]
        case .editing:
            return [
                "pencil", "pencil.circle", "pencil.circle.fill", "pencil.tip", "pencil.tip.crop.circle",
                "pencil.and.outline", "pencil.slash", "square.and.pencil", "scribble",
                "paintbrush", "paintbrush.fill", "paintbrush.pointed", "paintbrush.pointed.fill",
                "paintpalette", "paintpalette.fill", "eyedropper", "eyedropper.halffull", "eyedropper.full",
                "scissors", "crop", "crop.rotate", "rotate.left", "rotate.right",
                "flip.horizontal", "flip.horizontal.fill", "camera.filters",
                "slider.horizontal.3", "slider.horizontal.below.rectangle", "slider.vertical.3", "tuningfork",
                "metronome", "metronome.fill", "dial.min", "dial.max", "dial.min.fill", "dial.max.fill",
                "cube", "cube.fill", "cube.transparent", "cube.transparent.fill", "shippingbox", "shippingbox.fill",
                "archivebox", "archivebox.fill", "tray", "tray.fill", "tray.2", "tray.2.fill", "tray.full",
                "tray.full.fill", "externaldrive", "externaldrive.fill", "opticaldiscdrive", "opticaldiscdrive.fill",
                "tv", "tv.fill", "music.note", "music.note.list", "music.quarternote.3"
            ]
        case .development:
            return [
                "hammer", "hammer.fill", "hammer.circle", "hammer.circle.fill", "wrench", "wrench.fill",
                "wrench.and.screwdriver", "wrench.and.screwdriver.fill", "screwdriver", "screwdriver.fill",
                "terminal", "terminal.fill", "curlybraces", "curlybraces.square", "curlybraces.square.fill",
                "function", "command", "option", "control", "shift", "capslock", "escape",
                "delete.left", "delete.right", "clear", "clear.fill", "return", "chevron.left.forwardslash.chevron.right",
                "triangle", "triangle.fill", "diamond", "diamond.fill", "hexagon",
                "hexagon.fill", "octagon", "octagon.fill", "rhombus", "rhombus.fill", "seal", "seal.fill",
                "checkmark", "checkmark.circle", "checkmark.circle.fill", "checkmark.square", "checkmark.square.fill",
                "checkmark.rectangle", "checkmark.rectangle.fill", "xmark", "xmark.circle", "xmark.circle.fill",
                "xmark.square", "xmark.square.fill", "xmark.rectangle", "xmark.rectangle.fill", "questionmark",
                "questionmark.circle", "questionmark.circle.fill", "questionmark.square", "questionmark.square.fill",
                "exclamationmark", "exclamationmark.circle", "exclamationmark.circle.fill", "exclamationmark.triangle",
                "exclamationmark.triangle.fill", "exclamationmark.square", "exclamationmark.square.fill",
                "info", "info.circle", "info.circle.fill", "info.square", "info.square.fill", "lightbulb",
                "lightbulb.fill", "lightbulb.slash", "lightbulb.slash.fill", "gear", "gearshape", "gearshape.fill",
                "gearshape.2", "gearshape.2.fill", "ellipsis", "ellipsis.circle", "ellipsis.circle.fill",
                "ellipsis.rectangle", "ellipsis.rectangle.fill", "plus", "plus.circle", "plus.circle.fill",
                "plus.square", "plus.square.fill", "minus", "minus.circle", "minus.circle.fill", "minus.square",
                "minus.square.fill", "multiply", "multiply.circle", "multiply.circle.fill", "multiply.square",
                "multiply.square.fill", "divide", "divide.circle", "divide.circle.fill", "divide.square",
                "divide.square.fill", "equal", "equal.circle", "equal.circle.fill", "equal.square", "equal.square.fill"
            ]
        case .custom:
            return []
        }
    }
}

// MARK: - Icon Category Cache

/// 管理图标分类的缓存，避免重复创建大数组
class IconCategoryCache {
    static let shared = IconCategoryCache()

    private var cache: [IconCategory: [String]] = [:]
    private let cacheQueue = DispatchQueue(label: "icon.category.cache", qos: .utility)
    private var isClearing = false // 防止重复清理

    private init() {}

    func getSymbols(for category: IconCategory) -> [String] {
        return cacheQueue.sync {
            if let cached = cache[category] {
                return cached
            }

            let symbols = category._sfSymbols
            cache[category] = symbols
            return symbols
        }
    }

    /// 清理缓存（异步执行，避免阻塞主线程）
    func clearCache() {
        guard !isClearing else { return } // 防止重复清理

        isClearing = true
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            self.cache.removeAll()
            self.isClearing = false

            DispatchQueue.main.async {
                print("IconCategoryCache: Cache cleared")
            }
        }
    }

    /// 清理特定分类的缓存（异步执行）
    func clearCache(for category: IconCategory) {
        cacheQueue.async { [weak self] in
            self?.cache.removeValue(forKey: category)
        }
    }

    /// 同步清理缓存（避免使用，容易导致卡死）
    func clearCacheSync() {
        // 统一使用异步清理，避免同步操作导致卡死
        clearCache()
    }
}

// MARK: - Icon Provider Protocol

protocol IconProvider {
    func loadIcon(type: IconType, size: CGFloat) -> NSImage?
    func getAllIcons(category: IconCategory) -> [IconType]
}

// MARK: - Icon Manager

class IconManager: ObservableObject {
    static let shared = IconManager()

    private let sfSymbolProvider = SFSymbolProvider()

    // 内存管理
    private var iconCache: [String: NSImage] = [:]
    private let maxCacheSize = 50
    private var cacheAccessOrder: [String] = []
    private let cacheQueue = DispatchQueue(label: "IconManager.cache", qos: .utility)
    private var isClearing = false // 防止重复清理

    private init() {}
    
    func getIcon(type: IconType, size: CGFloat) -> NSImage? {
        let cacheKey = "\(type)_\(size)"

        // 检查缓存
        if let cachedIcon = getCachedIcon(for: cacheKey) {
            return cachedIcon
        }

        // 加载新图标
        if let icon = sfSymbolProvider.loadIcon(type: type, size: size) {
            cacheIcon(icon, for: cacheKey)
            return icon
        }

        return nil
    }
    
    func getAllIcons(category: IconCategory) -> [IconType] {
        // Only SF Symbols for now
        return category.sfSymbols.map { IconType.sfSymbol($0) }
    }
    
    func searchIcons(query: String) -> [IconType] {
        var results: [IconType] = []

        // Search SF Symbols only
        for category in IconCategory.allCases {
            let sfIcons = category.sfSymbols.filter { $0.localizedCaseInsensitiveContains(query) }
            results.append(contentsOf: sfIcons.map { IconType.sfSymbol($0) })
        }

        return results
    }

    // MARK: - Memory Management

    /// 管理图标缓存，实现LRU策略
    private func manageCacheSize() {
        while iconCache.count > maxCacheSize {
            if let oldestKey = cacheAccessOrder.first {
                iconCache.removeValue(forKey: oldestKey)
                cacheAccessOrder.removeFirst()
            } else {
                break
            }
        }
    }

    /// 获取缓存的图标，更新访问顺序
    private func getCachedIcon(for key: String) -> NSImage? {
        if let icon = iconCache[key] {
            // 更新访问顺序
            if let index = cacheAccessOrder.firstIndex(of: key) {
                cacheAccessOrder.remove(at: index)
            }
            cacheAccessOrder.append(key)
            return icon
        }
        return nil
    }

    /// 缓存图标
    private func cacheIcon(_ icon: NSImage, for key: String) {
        iconCache[key] = icon
        cacheAccessOrder.append(key)
        manageCacheSize()
    }

    /// 清理所有缓存
    func clearCache() {
        // 防止重复清理
        guard !isClearing else {
            print("IconManager: Cache clearing already in progress, skipping")
            return
        }

        isClearing = true

        // 在专用队列中执行清理，避免阻塞
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            self.iconCache.removeAll()
            self.cacheAccessOrder.removeAll()

            DispatchQueue.main.async {
                self.isClearing = false
                print("IconManager: Icon cache cleared")
            }
        }
    }
}

// MARK: - SF Symbol Provider

class SFSymbolProvider: IconProvider {
    func loadIcon(type: IconType, size: CGFloat) -> NSImage? {
        guard case .sfSymbol(let symbolName) = type else { return nil }
        
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .medium, scale: .large)
        
        if let icon = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            let configuredIcon = icon.withSymbolConfiguration(config) ?? icon
            configuredIcon.size = NSSize(width: size, height: size)
            return configuredIcon
        }
        
        return nil
    }
    
    func getAllIcons(category: IconCategory) -> [IconType] {
        return category.sfSymbols.map { IconType.sfSymbol($0) }
    }
}



// MARK: - Icon Extensions

extension IconType: Equatable {
    static func == (lhs: IconType, rhs: IconType) -> Bool {
        switch (lhs, rhs) {
        case (.sfSymbol(let a), .sfSymbol(let b)):
            return a == b
        }
    }
}

extension IconType: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .sfSymbol(let name):
            hasher.combine("sf")
            hasher.combine(name)
        }
    }
}
