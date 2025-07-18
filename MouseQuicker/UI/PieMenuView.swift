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
    private let menuRadius: CGFloat = 120.0
    private let innerRadius: CGFloat = 35.0
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

        // Draw center circle FIRST (before sectors and text)
        drawCenterCircle(in: context, center: center)

        // Draw sectors (including icons)
        for (index, sector) in sectors.enumerated() {
            let isHovered = index == hoveredIndex
            drawSector(sector, in: context, center: center, isHovered: isHovered)
        }

        // Draw center text LAST (on top of everything)
        if hoveredIndex >= 0 && hoveredIndex < sectors.count {
            let hoveredSector = sectors[hoveredIndex]
            drawCenterText(hoveredSector.item.title, at: center)
        }
    }
    
    private func drawBackgroundCircle(in context: CGContext, center: CGPoint) {
        // Create simple dark transparent background like Pie Menu (no gradient!)
        context.saveGState()

        // Use single dark transparent color like Pie Menu
        let backgroundColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)

        // Draw simple solid circle like Pie Menu
        context.addArc(center: center, radius: menuRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.setFillColor(backgroundColor)
        context.fillPath()

        // Cut out inner circle
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0)) // transparent
        context.setBlendMode(.clear)
        context.fillPath()
        context.setBlendMode(.normal)

        context.restoreGState()

        // Add subtle outer border with white color
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        context.addArc(center: center, radius: menuRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()

        // Add inner border for the center circle
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.15).cgColor)
        context.setLineWidth(0.5)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
    }
    
    private func drawSector(_ sector: PieMenuSector, in context: CGContext, center: CGPoint, isHovered: Bool) {
        // Calculate sector path
        let startAngle = sector.startAngle
        let endAngle = sector.endAngle

        if isHovered {
            // Draw enhanced hover effect similar to Pie Menu
            drawHoveredSector(startAngle: startAngle, endAngle: endAngle, center: center, context: context)
        } else {
            // Draw normal sector with subtle background
            drawNormalSector(startAngle: startAngle, endAngle: endAngle, center: center, context: context)
        }

        // Draw icon and text
        drawSectorContent(sector, in: context, center: center, isHovered: isHovered)
    }

    private func drawNormalSector(startAngle: CGFloat, endAngle: CGFloat, center: CGPoint, context: CGContext) {
        // Create sector path (ring shape, not full pie)
        context.beginPath()
        context.addArc(center: center, radius: innerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        context.addArc(center: center, radius: menuRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        context.closePath()

        // Very subtle fill for normal state
        context.setFillColor(NSColor.controlColor.withAlphaComponent(0.1).cgColor)
        context.fillPath()

        // Draw subtle border lines between sectors
        context.beginPath()
        context.move(to: CGPoint(x: center.x + cos(startAngle) * innerRadius, y: center.y + sin(startAngle) * innerRadius))
        context.addLine(to: CGPoint(x: center.x + cos(startAngle) * menuRadius, y: center.y + sin(startAngle) * menuRadius))
        context.setStrokeColor(NSColor.separatorColor.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        context.strokePath()
    }

    private func drawHoveredSector(startAngle: CGFloat, endAngle: CGFloat, center: CGPoint, context: CGContext) {
        // Create sector path (ring shape)
        context.beginPath()
        context.addArc(center: center, radius: innerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        context.addArc(center: center, radius: menuRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        context.closePath()

        // Gray highlight like Pie Menu
        let highlightColor = CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.3)
        context.setFillColor(highlightColor)
        context.fillPath()

        // Subtle border for hovered sector
        context.beginPath()
        context.move(to: CGPoint(x: center.x + cos(startAngle) * innerRadius, y: center.y + sin(startAngle) * innerRadius))
        context.addLine(to: CGPoint(x: center.x + cos(startAngle) * menuRadius, y: center.y + sin(startAngle) * menuRadius))
        context.move(to: CGPoint(x: center.x + cos(endAngle) * innerRadius, y: center.y + sin(endAngle) * innerRadius))
        context.addLine(to: CGPoint(x: center.x + cos(endAngle) * menuRadius, y: center.y + sin(endAngle) * menuRadius))
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(0.5)
        context.strokePath()
    }
    
    private func drawSectorContent(_ sector: PieMenuSector, in context: CGContext, center: CGPoint, isHovered: Bool) {
        let midAngle = (sector.startAngle + sector.endAngle) / 2
        let iconRadius = (menuRadius + innerRadius) / 2
        
        // Calculate icon position
        let iconX = center.x + cos(midAngle) * iconRadius
        let iconY = center.y + sin(midAngle) * iconRadius
        let iconPoint = CGPoint(x: iconX, y: iconY)
        
        // Draw icon with caching optimization - increased size for better visibility
        let iconSize: CGFloat = isHovered ? 28 : 24
        let iconRect = CGRect(
            x: iconPoint.x - iconSize/2,
            y: iconPoint.y - iconSize/2,
            width: iconSize,
            height: iconSize
        )

        // Use the new icon system to get the appropriate icon
        let iconType = IconType.sfSymbol(sector.item.iconName) // Default to SF Symbol for now
        if let icon = IconManager.shared.getIcon(type: iconType, size: iconSize) {
            drawTintedIcon(icon, in: iconRect, color: NSColor.white)
        }
    }

    private func drawTintedIcon(_ icon: NSImage, in rect: CGRect, color: NSColor) {
        NSGraphicsContext.saveGraphicsState()

        // Create high-quality rendering hints for crisp icons
        let renderingHints: [NSImageRep.HintKey: Any] = [
            .interpolation: NSImageInterpolation.high,
            .ctm: NSAffineTransform()
        ]

        // Create a copy of the icon and set it as template for better tinting
        let templateIcon = icon.copy() as! NSImage
        templateIcon.isTemplate = true

        // Set high-quality rendering
        templateIcon.cacheMode = .never

        // Use NSImage's built-in tinting for better quality
        if let cgImage = templateIcon.cgImage(forProposedRect: nil, context: nil, hints: renderingHints) {
            if let cgContext = NSGraphicsContext.current?.cgContext {
                cgContext.saveGState()

                // Enable high-quality rendering
                cgContext.interpolationQuality = .high
                cgContext.setShouldAntialias(true)
                cgContext.setShouldSmoothFonts(true)

                // Set the fill color
                cgContext.setFillColor(color.cgColor)

                // Draw the icon as a mask and fill with the color
                cgContext.clip(to: rect, mask: cgImage)
                cgContext.fill(rect)

                cgContext.restoreGState()
            }
        }

        NSGraphicsContext.restoreGraphicsState()
    }

    private func createHighQualityIcon(named iconName: String, size: CGFloat) -> NSImage? {
        // Create SF Symbol with proper configuration for crisp rendering
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .medium, scale: .large)

        if let icon = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            // Apply the configuration for better quality
            let configuredIcon = icon.withSymbolConfiguration(config) ?? icon

            // Set the size explicitly for pixel-perfect rendering
            configuredIcon.size = NSSize(width: size, height: size)

            return configuredIcon
        }

        return nil
    }

    private func drawCenterText(_ text: String, at center: CGPoint) {
        // Draw text in the center area with coordinated styling
        NSGraphicsContext.saveGraphicsState()

        // Calculate text size first
        let font = NSFont.systemFont(ofSize: 14, weight: .medium)

        // Create softer white color - less harsh than pure white
        let softWhiteColor = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)

        // Create text attributes with softer white color
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: softWhiteColor
        ]
        let textSize = text.size(withAttributes: textAttributes)

        // No background - just display text directly

        // Draw text with softer white color
        let textRect = CGRect(
            x: center.x - textSize.width/2,
            y: center.y - textSize.height/2,
            width: textSize.width,
            height: textSize.height
        )

        // Create attributed string with softer white color
        let attributedString = NSAttributedString(string: text, attributes: textAttributes)

        // Draw the text
        attributedString.draw(in: textRect)

        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawSectorText(_ text: String, at point: CGPoint, in context: CGContext, isHovered: Bool) {
        let textColor = isHovered ? NSColor.white : NSColor.labelColor
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let textRect = CGRect(
            x: point.x - textSize.width/2,
            y: point.y - 30,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
    private func drawCenterCircle(in context: CGContext, center: CGPoint) {
        let isDarkMode = NSApp.effectiveAppearance.name == .darkAqua

        // Draw inner circle with subtle gradient
        context.saveGState()

        // Create gradient for center circle
        let centerStartColor = isDarkMode ?
            NSColor.controlBackgroundColor.withAlphaComponent(0.95) :
            NSColor.controlBackgroundColor.withAlphaComponent(0.98)
        let centerEndColor = isDarkMode ?
            NSColor.controlBackgroundColor.withAlphaComponent(0.8) :
            NSColor.controlBackgroundColor.withAlphaComponent(0.9)

        let centerGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [centerStartColor.cgColor, centerEndColor.cgColor] as CFArray,
                                      locations: [0.0, 1.0])!

        // Clip to center circle
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.clip()

        // Draw radial gradient for center
        context.drawRadialGradient(centerGradient,
                                 startCenter: center, startRadius: 0,
                                 endCenter: center, endRadius: innerRadius,
                                 options: [])

        context.restoreGState()

        // Add subtle border for center circle
        context.setStrokeColor(NSColor.separatorColor.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(0.5)
        context.addArc(center: center, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
    }
    
    // MARK: - PieMenuViewProtocol Implementation
    
    func updateMenuItems(_ items: [ShortcutItem]) {
        menuItems = items
    }
    
    func animateAppearance(completion: @escaping () -> Void) {
        // Start from small scale and transparent
        layer?.transform = CATransform3DMakeScale(0.3, 0.3, 1.0)
        layer?.opacity = 0.0

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        // Create spring-like scale animation
        let scaleAnimation = CASpringAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.3
        scaleAnimation.toValue = 1.0
        scaleAnimation.duration = 0.4
        scaleAnimation.damping = 15.0
        scaleAnimation.stiffness = 300.0
        scaleAnimation.initialVelocity = 0.0

        // Smooth opacity fade-in
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.0
        opacityAnimation.toValue = 1.0
        opacityAnimation.duration = 0.25
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        // Add subtle rotation for more dynamic feel
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = -0.1
        rotationAnimation.toValue = 0.0
        rotationAnimation.duration = 0.4
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer?.add(scaleAnimation, forKey: "scaleAppear")
        layer?.add(opacityAnimation, forKey: "opacityAppear")
        layer?.add(rotationAnimation, forKey: "rotationAppear")

        layer?.transform = CATransform3DIdentity
        layer?.opacity = 1.0

        CATransaction.commit()
    }
    
    func animateDisappearance(completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)

        // Quick scale down with ease-in timing
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 0.2
        scaleAnimation.duration = 0.2
        scaleAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 1.0, 1.0)

        // Fast opacity fade-out
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 0.15
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)

        // Slight rotation for dynamic exit
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = 0.05
        rotationAnimation.duration = 0.2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)

        layer?.add(scaleAnimation, forKey: "scaleDisappear")
        layer?.add(opacityAnimation, forKey: "opacityDisappear")
        layer?.add(rotationAnimation, forKey: "rotationDisappear")

        layer?.transform = CATransform3DMakeScale(0.2, 0.2, 1.0)
        layer?.opacity = 0.0

        CATransaction.commit()
    }

    func animateClickFeedback() {
        // Quick scale pulse for click feedback
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 0.95
        scaleAnimation.duration = 0.1
        scaleAnimation.autoreverses = true
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        layer?.add(scaleAnimation, forKey: "clickFeedback")
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
        guard self.window != nil else {
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
            // Add click feedback animation
            animateClickFeedback()
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
