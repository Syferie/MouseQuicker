//
//  PieMenuView.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit
import QuartzCore

/// Custom NSView that renders a circular pie menu
class PieMenuView: NSView, PieMenuViewProtocol {
    
    // MARK: - Properties
    
    weak var delegate: PieMenuViewDelegate?
    var menuItems: [ShortcutItem] = [] {
        didSet {
            updateSectors()
            needsDisplay = true
        }
    }
    
    private(set) var hoveredIndex: Int = -1
    
    // MARK: - Private Properties

    private var sectors: [PieMenuSector] = []
    private var trackingArea: NSTrackingArea?
    private let menuRadius: CGFloat = 100.0
    private let innerRadius: CGFloat = 30.0
    private let sectorPadding: CGFloat = 2.0

    // Performance optimization: cache frequently used values
    private var cachedCenter: CGPoint = .zero
    private var cachedIconCache: [String: NSImage] = [:]
    private var needsRecalculation = true

    // Global keyboard monitoring for ESC key
    private var keyboardMonitor: Any?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        setupTrackingArea()
        setupKeyboardMonitoring()
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            setupTrackingArea()
            setupKeyboardMonitoring()
        } else {
            cleanupKeyboardMonitoring()
        }
    }

    deinit {
        cleanupKeyboardMonitoring()
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }
    
    private func setupTrackingArea() {
        if let existingTrackingArea = trackingArea {
            removeTrackingArea(existingTrackingArea)
        }
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Performance optimization: measure rendering time
        withPerformanceMeasurement(label: "PieMenuRender") {
            // Clear the background
            context.clear(dirtyRect)

            // Draw the pie menu
            drawPieMenu(in: context)
        }
    }
    
    private func drawPieMenu(in context: CGContext) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Draw background circle with glass effect
        drawBackgroundCircle(in: context, center: center)
        
        // Draw sectors
        for (index, sector) in sectors.enumerated() {
            let isHovered = index == hoveredIndex
            drawSector(sector, in: context, center: center, isHovered: isHovered)
        }
        
        // Draw center circle
        drawCenterCircle(in: context, center: center)
    }
    
    private func drawBackgroundCircle(in context: CGContext, center: CGPoint) {
        // Create glass effect background
        context.setFillColor(NSColor.controlBackgroundColor.withAlphaComponent(0.7).cgColor)
        context.addArc(center: center, radius: menuRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
        
        // Add border
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(1.0)
        context.addArc(center: center, radius: menuRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
    }
    
    private func drawSector(_ sector: PieMenuSector, in context: CGContext, center: CGPoint, isHovered: Bool) {
        // Calculate sector path
        let startAngle = sector.startAngle
        let endAngle = sector.endAngle
        
        // Create sector path
        context.beginPath()
        context.move(to: center)
        context.addArc(center: center, radius: menuRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        context.closePath()
        
        // Fill sector
        let fillColor = isHovered ? NSColor.selectedControlColor.withAlphaComponent(0.8) : NSColor.controlColor.withAlphaComponent(0.5)
        context.setFillColor(fillColor.cgColor)
        context.fillPath()
        
        // Draw sector border
        context.beginPath()
        context.addArc(center: center, radius: menuRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(0.5)
        context.strokePath()
        
        // Draw icon and text
        drawSectorContent(sector, in: context, center: center, isHovered: isHovered)
    }
    
    private func drawSectorContent(_ sector: PieMenuSector, in context: CGContext, center: CGPoint, isHovered: Bool) {
        let midAngle = (sector.startAngle + sector.endAngle) / 2
        let iconRadius = (menuRadius + innerRadius) / 2
        
        // Calculate icon position
        let iconX = center.x + cos(midAngle) * iconRadius
        let iconY = center.y + sin(midAngle) * iconRadius
        let iconPoint = CGPoint(x: iconX, y: iconY)
        
        // Draw icon with caching optimization
        let iconSize: CGFloat = isHovered ? 20 : 16
        let iconRect = CGRect(
            x: iconPoint.x - iconSize/2,
            y: iconPoint.y - iconSize/2,
            width: iconSize,
            height: iconSize
        )

        // Use cached icon if available
        if let cachedIcon = cachedIconCache[sector.item.iconName] {
            cachedIcon.draw(in: iconRect)
        } else if let icon = NSImage(systemSymbolName: sector.item.iconName, accessibilityDescription: nil) {
            // Cache the icon for future use
            cachedIconCache[sector.item.iconName] = icon
            icon.draw(in: iconRect)
        }
        
        // Draw text if hovered
        if isHovered {
            drawSectorText(sector.item.title, at: iconPoint, in: context)
        }
    }
    
    private func drawSectorText(_ text: String, at point: CGPoint, in context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = CGRect(
            x: point.x - textSize.width/2,
            y: point.y - 25,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
    private func drawCenterCircle(in context: CGContext, center: CGPoint) {
        // Draw inner circle
        context.setFillColor(NSColor.controlBackgroundColor.cgColor)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
        
        // Add border
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(1.0)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
    }
    
    // MARK: - PieMenuViewProtocol Implementation
    
    func updateMenuItems(_ items: [ShortcutItem]) {
        menuItems = items
    }
    
    func animateAppearance(completion: @escaping () -> Void) {
        // Scale from 0 to 1
        layer?.transform = CATransform3DMakeScale(0.1, 0.1, 1.0)
        layer?.opacity = 0.0
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.1
        scaleAnimation.toValue = 1.0
        scaleAnimation.duration = 0.2
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.0
        opacityAnimation.toValue = 1.0
        opacityAnimation.duration = 0.2
        
        layer?.add(scaleAnimation, forKey: "scaleAppear")
        layer?.add(opacityAnimation, forKey: "opacityAppear")
        
        layer?.transform = CATransform3DIdentity
        layer?.opacity = 1.0
        
        CATransaction.commit()
    }
    
    func animateDisappearance(completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 0.1
        scaleAnimation.duration = 0.15
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 0.15
        
        layer?.add(scaleAnimation, forKey: "scaleDisappear")
        layer?.add(opacityAnimation, forKey: "opacityDisappear")
        
        layer?.transform = CATransform3DMakeScale(0.1, 0.1, 1.0)
        layer?.opacity = 0.0
        
        CATransaction.commit()
    }
    
    func sectorIndex(for point: NSPoint) -> Int {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx*dx + dy*dy)

        // Check if point is within the menu ring
        guard distance >= innerRadius && distance <= menuRadius else {
            return -1
        }

        // Calculate angle
        let angle = atan2(dy, dx)
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle

        // Find which sector contains this angle
        for (index, sector) in sectors.enumerated() {
            let startAngle = sector.startAngle < 0 ? sector.startAngle + 2 * .pi : sector.startAngle
            let endAngle = sector.endAngle < 0 ? sector.endAngle + 2 * .pi : sector.endAngle

            // Handle sectors that cross the 0-degree boundary
            if startAngle > endAngle {
                // Sector crosses 0 degrees (e.g., from 5.5 to 0.5 radians)
                if normalizedAngle >= startAngle || normalizedAngle <= endAngle {
                    return index
                }
            } else {
                // Normal sector
                if normalizedAngle >= startAngle && normalizedAngle <= endAngle {
                    return index
                }
            }
        }

        return -1
    }
    
    // MARK: - Private Helpers
    
    private func updateSectors() {
        sectors.removeAll()
        
        guard !menuItems.isEmpty else { return }
        
        let anglePerSector = (2 * CGFloat.pi) / CGFloat(menuItems.count)
        let startAngle: CGFloat = -CGFloat.pi / 2 // Start at top
        
        for (index, item) in menuItems.enumerated() {
            let sectorStartAngle = startAngle + CGFloat(index) * anglePerSector
            let sectorEndAngle = sectorStartAngle + anglePerSector
            
            let sector = PieMenuSector(
                item: item,
                startAngle: sectorStartAngle,
                endAngle: sectorEndAngle
            )
            sectors.append(sector)
        }
    }
}

// MARK: - Mouse Events

extension PieMenuView {
    override func mouseDown(with event: NSEvent) {
        print("PieMenuView: mouseDown received at \(event.locationInWindow)")

        // Convert window coordinates to view coordinates
        guard let window = self.window else {
            print("PieMenuView: No window found")
            return
        }

        let windowPoint = event.locationInWindow
        let localPoint = convert(windowPoint, from: nil)

        // Check if the click is within this view's bounds
        if !bounds.contains(localPoint) {
            print("PieMenuView: Click outside view bounds, requesting dismissal")
            delegate?.pieMenuViewDidRequestDismissal(self)
            return
        }

        let index = sectorIndex(for: localPoint)

        // Calculate distance from center for debugging
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = localPoint.x - center.x
        let dy = localPoint.y - center.y
        let distance = sqrt(dx*dx + dy*dy)

        print("PieMenuView: windowPoint=\(windowPoint), localPoint=\(localPoint), sectorIndex=\(index), distance=\(distance), innerRadius=\(innerRadius), menuRadius=\(menuRadius)")

        if index >= 0 {
            print("PieMenuView: Clicked on sector \(index)")
            delegate?.pieMenuView(self, didClickSectorAt: index)
        } else {
            // Clicked outside the menu sectors, dismiss the menu
            print("PieMenuView: Clicked outside menu sectors, requesting dismissal")
            delegate?.pieMenuViewDidRequestDismissal(self)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        let newHoveredIndex = sectorIndex(for: localPoint)
        
        if newHoveredIndex != hoveredIndex {
            let oldIndex = hoveredIndex
            hoveredIndex = newHoveredIndex
            
            if oldIndex >= 0 || newHoveredIndex >= 0 {
                needsDisplay = true
            }
            
            if newHoveredIndex >= 0 {
                delegate?.pieMenuView(self, didHoverSectorAt: newHoveredIndex)
            } else {
                delegate?.pieMenuViewDidExitAllSectors(self)
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if hoveredIndex >= 0 {
            hoveredIndex = -1
            needsDisplay = true
            delegate?.pieMenuViewDidExitAllSectors(self)
        }
    }
}

// MARK: - Keyboard Events

extension PieMenuView {
    override var acceptsFirstResponder: Bool { return true }

    // MARK: - Keyboard Monitoring

    private func setupKeyboardMonitoring() {
        cleanupKeyboardMonitoring()

        // Set up global keyboard monitor for ESC key
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                print("PieMenuView: Global ESC key detected, requesting dismissal")
                DispatchQueue.main.async {
                    self?.delegate?.pieMenuViewDidRequestDismissal(self!)
                }
            }
        }

        print("PieMenuView: Global keyboard monitoring started")
    }

    private func cleanupKeyboardMonitoring() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
            print("PieMenuView: Global keyboard monitoring stopped")
        }
    }

    override func keyDown(with event: NSEvent) {
        print("PieMenuView: keyDown received, keyCode=\(event.keyCode)")
        if event.keyCode == 53 { // ESC key
            print("PieMenuView: ESC key pressed, requesting dismissal")
            delegate?.pieMenuViewDidRequestDismissal(self)
        } else {
            super.keyDown(with: event)
        }
    }
}

// MARK: - Supporting Types

private struct PieMenuSector {
    let item: ShortcutItem
    let startAngle: CGFloat
    let endAngle: CGFloat
}
