//
//  AuthenticationService.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import FirebaseCore
import Combine


enum AuthenticationError: Error, LocalizedError {
    case userNotFound
    case invalidCredentials
    case emailNotVerified
    case phoneNotVerified
    case emailAlreadyInUse
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "The email used does not exist"
        case .invalidCredentials:
            return "Invalid email or password."
        case .emailNotVerified:
            return "Please verify your email before continuing."
        case .phoneNotVerified:
            return "Please verify your phone number before continuing."
        case .emailAlreadyInUse:
            return "This email is already in use"
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let message):
            return message
        }
    }
}

class AuthenticationService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false

    private let auth = Auth.auth()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        // Listen for authentication state changes
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Email/Password Authentication

    func signUpWithEmail(email: String, password: String) async throws -> FirebaseAuth.User {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            return result.user
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func signInWithEmail(email: String, password: String) async throws -> FirebaseAuth.User {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return result.user
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func sendEmailVerification() async throws {
        guard let user = currentUser else {
            throw AuthenticationError.userNotFound
        }

        do {
            try await user.sendEmailVerification()
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func reloadUser() async throws {
        guard let user = currentUser else {
            throw AuthenticationError.userNotFound
        }

        try await user.reload()
        self.currentUser = auth.currentUser
    }

    // MARK: - Phone Authentication

    func sendPhoneVerification(phoneNumber: String) async throws -> String {
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            return verificationID
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func verifyPhoneCode(verificationID: String, code: String) async throws -> FirebaseAuth.User {
        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code
            )

            // Link phone credential to existing user if logged in
            if let user = currentUser {
                let result = try await user.link(with: credential)
                return result.user
            } else {
                // Sign in with phone credential
                let result = try await auth.signIn(with: credential)
                return result.user
            }
        } catch {
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws -> FirebaseAuth.User {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthenticationError.unknown("Failed to get Google Client ID")
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthenticationError.unknown("Failed to get root view controller")
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                throw AuthenticationError.unknown("Failed to get ID token")
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            let authResult = try await auth.signIn(with: credential)
            return authResult.user
        } catch {
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Apple Sign-In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> FirebaseAuth.User {
        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthenticationError.unknown("Failed to get Apple ID token")
        }

        let nonce = randomNonceString()
        let appleCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        do {
            let result = try await auth.signIn(with: appleCredential)
            return result.user
        } catch {
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Session Management

    func signOut() throws {
        do {
            try auth.signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthenticationError.userNotFound
        }

        do {
            try await user.delete()
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func getCurrentUser() -> FirebaseAuth.User? {
        return auth.currentUser
    }

    // MARK: - Utilities

    func isEmailVerified() -> Bool {
        return currentUser?.isEmailVerified ?? false
    }

    func isPhoneVerified() -> Bool {
        guard let user = currentUser else { return false }
        return user.providerData.contains { $0.providerID == "phone" }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw AuthenticationError.userNotFound
        }

        // Re-authenticate user with current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)

        do {
            try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPassword)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Private Helpers

    private func mapFirebaseError(_ error: Error) -> Error {
        let nsError = error as NSError
        print("🔥 [Firebase Error] Code: \(nsError.code)")
        print("🔥 [Firebase Error] Domain: \(nsError.domain)")
        print("🔥 [Firebase Error] Description: \(nsError.localizedDescription)")
        print("🔥 [Firebase Error] UserInfo: \(nsError.userInfo)")

        guard let authError = AuthErrorCode(rawValue: nsError.code) else {
            print("🔥 [Firebase Error] Could not map to AuthErrorCode")
            return AuthenticationError.unknown(error.localizedDescription)
        }

        print("🔥 [Firebase Error] AuthErrorCode: \(authError)")

        switch authError {
        case .userNotFound, .invalidEmail:
            print("🔥 [Firebase Error] Mapped to: userNotFound")
            return AuthenticationError.userNotFound
        case .wrongPassword, .invalidCredential:
            print("🔥 [Firebase Error] Mapped to: invalidCredentials")
            return AuthenticationError.invalidCredentials
        case .emailAlreadyInUse:
            print("🔥 [Firebase Error] Mapped to: emailAlreadyInUse")
            return AuthenticationError.emailAlreadyInUse
        case .networkError:
            print("🔥 [Firebase Error] Mapped to: networkError")
            return AuthenticationError.networkError
        default:
            print("🔥 [Firebase Error] Mapped to: unknown")
            return AuthenticationError.unknown(error.localizedDescription)
        }
    }

    // Generate random nonce for Apple Sign-In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
