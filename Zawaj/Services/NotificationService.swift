//
//  NotificationService.swift
//  Zawaj
//
//  Created on 2025-12-26.
//

import Foundation
import UIKit
import Combine
import FirebaseMessaging
import UserNotifications

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var fcmToken: String?

    private let firestoreService = FirestoreService()

    private override init() {
        super.init()
    }

    /// Request notification permissions and register for remote notifications
    func requestAuthorization() {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
                return
            }

            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission denied")
            }
        }

        // Set FCM messaging delegate
        Messaging.messaging().delegate = self
    }

    /// Update the FCM token in Firestore for the current user
    func updateFCMToken(for userId: String) {
        guard let token = fcmToken else {
            print("No FCM token available to update")
            return
        }

        Task {
            do {
                try await firestoreService.updateUserProfile(userId: userId, updates: [
                    "fcmToken": token
                ])
                print("FCM token updated in Firestore")
            } catch {
                print("Failed to update FCM token: \(error.localizedDescription)")
            }
        }
    }

    /// Clear the FCM token when user logs out
    func clearFCMToken(for userId: String) {
        Task {
            do {
                try await firestoreService.updateUserProfile(userId: userId, updates: [
                    "fcmToken": ""
                ])
                print("FCM token cleared in Firestore")
            } catch {
                print("Failed to clear FCM token: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification types based on data
        if let notificationType = userInfo["type"] as? String {
            handleNotificationTap(type: notificationType, userInfo: userInfo)
        }

        completionHandler()
    }

    private func handleNotificationTap(type: String, userInfo: [AnyHashable: Any]) {
        // Handle navigation based on notification type
        switch type {
        case "partner_request":
            // Navigate to partner requests
            NotificationCenter.default.post(name: .navigateToPartnerRequests, object: nil)
        case "partner_accepted", "partner_completed", "new_questions", "partner_reminder":
            // Navigate to questions
            NotificationCenter.default.post(name: .navigateToQuestions, object: nil)
        default:
            break
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        print("FCM Token received: \(token)")
        self.fcmToken = token

        // Post notification for token refresh
        NotificationCenter.default.post(
            name: .fcmTokenRefreshed,
            object: nil,
            userInfo: ["token": token]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let fcmTokenRefreshed = Notification.Name("fcmTokenRefreshed")
    static let navigateToPartnerRequests = Notification.Name("navigateToPartnerRequests")
    static let navigateToQuestions = Notification.Name("navigateToQuestions")
}
