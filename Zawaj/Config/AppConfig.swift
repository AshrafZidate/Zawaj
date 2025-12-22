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
    static let autoLoginEnabled = true

    /// Credentials for automatic login
    /// IMPORTANT: Use a real test account email and password
    /// Never commit real user credentials to git!
    static let autoLoginEmail = "ashzidate@hotmail.co.uk"  // Replace with your test account
    static let autoLoginPassword = "123456"  // Replace with your test password

    // MARK: - Environment

    /// Returns true if running in development/testing mode
    static var isTestMode: Bool {
        return autoLoginEnabled
    }
}
