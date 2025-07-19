//
//  PieMenuProtocols.swift
//  MouseQuicker
//
//  Created by syferie on 2025/7/17.
//

import Foundation
import AppKit

// Note: This file contains protocols and types used by PieMenuController and PieMenuView
// The actual classes are defined in their respective files

// MARK: - MenuLayer

/// Enumeration for pie menu layers
enum MenuLayer: String, Codable, CaseIterable {
    case inner = "inner"
    case outer = "outer"

    /// Display name for the layer
    var displayName: String {
        switch self {
        case .inner: return "内层"
        case .outer: return "外层"
        }
    }
}

// Note: Notification names are now defined in AppCoordinator.swift



// Note: Protocols have been moved to their respective implementation files:
// - PieMenuControllerDelegate and PieMenuControllerProtocol are in PieMenuController.swift
// - PieMenuViewDelegate and PieMenuViewProtocol are in PieMenuView.swift
