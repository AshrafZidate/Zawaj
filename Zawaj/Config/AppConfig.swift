//
//  AppConfig.swift
//  Zawaj
//
//  Created on 2025-12-21.
//

import Foundation

struct AppConfig {
    // MARK: - Auto Login Settings

    /// Enable automatic login for testing with a real Firebase account
    /// Set to false before production release
    /// Uses credentials from DeveloperConfig.testAccounts[0]
    static var autoLoginEnabled: Bool {
        DeveloperConfig.isEnabled && DeveloperConfig.autoLoginEnabled
    }

    /// Credentials for automatic login - uses first test account from DeveloperConfig
    static var autoLoginEmail: String {
        DeveloperConfig.testAccounts.first?.email ?? ""
    }

    static var autoLoginPassword: String {
        DeveloperConfig.testAccounts.first?.password ?? ""
    }

    // MARK: - Environment

    /// Returns true if running in development/testing mode
    static var isTestMode: Bool {
        return DeveloperConfig.isEnabled
    }
}
