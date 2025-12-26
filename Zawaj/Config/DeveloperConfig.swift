//
//  DeveloperConfig.swift
//  Zawaj
//
//  Created on 2025-12-24.
//

import Foundation

/// Developer configuration for testing purposes.
/// Set `isEnabled` to true to show developer options in the app.
struct DeveloperConfig {
    /// Toggle this to enable/disable developer mode
    static let isEnabled = true

    /// When enabled, automatically logs into the first test account on app launch
    static let autoLoginEnabled = true

    /// Test accounts for quick switching during development
    /// Credentials are stored in DeveloperCredentials.swift (excluded from git)
    static var testAccounts: [(name: String, email: String, password: String)] {
        DeveloperCredentials.testAccounts
    }
}
