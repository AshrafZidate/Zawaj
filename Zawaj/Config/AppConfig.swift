//
//  AppConfig.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import Foundation

struct AppConfig {
    // MARK: - Development Settings

    /// Set to true to bypass authentication and go straight to dashboard
    /// WARNING: Set to false before production release
    static let isDevelopmentMode = true

    /// Development user ID to use when bypassing authentication
    /// This should match a real user ID in your Firestore for testing
    static let developmentUserId = "dev_user_123"
}
