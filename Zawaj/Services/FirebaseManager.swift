//
//  FirebaseManager.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseMessaging

class FirebaseManager {
    static let shared = FirebaseManager()

    private init() {}

    func configure() {
        FirebaseApp.configure()

        // Configure Firestore settings for offline persistence
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings

        // Set up analytics
        Analytics.setAnalyticsCollectionEnabled(true)

        print("Firebase configured successfully")
    }

    func configureMessaging(delegate: MessagingDelegate) {
        Messaging.messaging().delegate = delegate
    }
}
