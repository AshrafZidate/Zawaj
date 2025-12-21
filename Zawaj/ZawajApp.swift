//
//  ZawajApp.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI
import FirebaseCore

@main
struct ZawajApp: App {
    @StateObject private var authService = AuthenticationService()

    init() {
        // Configure Firebase on app launch
        FirebaseManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
