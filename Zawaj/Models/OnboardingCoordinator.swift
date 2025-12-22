//
//  OnboardingCoordinator.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import SwiftUI
import Combine
import FirebaseAuth

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case login
    case signUpEmail
    case signUpPassword
    case emailVerification
    case signUpFullName
    case signUpUsername
    case signUpGender
    case signUpBirthday
    case signUpRelationshipStatus
    case signUpMarriageTimeline
    case signUpTopicPriorities
    case signUpAddPartner
    case signUpAnswerPreference
    case enableNotifications
    case accountSetupLoading
    case completed

    var progress: Double {
        // Calculate progress based on step position
        // Welcome, login, emailVerification, accountSetupLoading, and completed don't count towards progress
        switch self {
        case .welcome:
            return 0.0
        case .login:
            return 0.0
        case .signUpEmail:
            return 0.08
        case .signUpPassword:
            return 0.17
        case .emailVerification:
            return 0.17
        case .signUpFullName:
            return 0.25
        case .signUpUsername:
            return 0.33
        case .signUpGender:
            return 0.42
        case .signUpBirthday:
            return 0.50
        case .signUpRelationshipStatus:
            return 0.58
        case .signUpMarriageTimeline:
            return 0.67
        case .signUpTopicPriorities:
            return 0.75
        case .signUpAddPartner:
            return 0.83
        case .signUpAnswerPreference:
            return 0.92
        case .enableNotifications:
            return 0.96
        case .accountSetupLoading:
            return 1.0
        case .completed:
            return 1.0
        }
    }
}

class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var navigationPath = NavigationPath()

    // MARK: - Initialization

    init() {
        // Skip to dashboard in development mode
        if AppConfig.isDevelopmentMode {
            currentStep = .completed
        }
    }

    // User data collected during onboarding
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var fullName: String = ""
    @Published var username: String = ""
    @Published var gender: String = ""
    @Published var birthday: Date = Date()
    @Published var phoneNumber: String = ""
    @Published var countryCode: String = "+1"
    @Published var relationshipStatus: String = ""
    @Published var marriageTimeline: String = ""
    @Published var topicPriorities: [String] = []
    @Published var partnerUsername: String = ""
    @Published var partnerConnected: Bool = false
    @Published var answerPreference: String = ""

    // Authentication state
    @Published var authenticationError: String?
    @Published var isLoading: Bool = false
    @Published var phoneVerificationID: String?

    // Services
    private let authService = AuthenticationService()
    private let firestoreService = FirestoreService()

    func nextStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        currentStep = nextStep
    }

    func previousStep() {
        guard currentStep.rawValue > 0,
              let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = previousStep
    }

    func skipToStep(_ step: OnboardingStep) {
        currentStep = step
    }

    func reset() {
        currentStep = .welcome
        email = ""
        password = ""
        fullName = ""
        username = ""
        gender = ""
        birthday = Date()
        phoneNumber = ""
        countryCode = "+1"
        relationshipStatus = ""
        marriageTimeline = ""
        topicPriorities = []
        partnerUsername = ""
        partnerConnected = false
        authenticationError = nil
        isLoading = false
        phoneVerificationID = nil
    }

    // MARK: - Authentication Methods

    func signUpWithEmail() async {
        isLoading = true
        authenticationError = nil

        do {
            _ = try await authService.signUpWithEmail(email: email, password: password)
            try await authService.sendEmailVerification()

            await MainActor.run {
                isLoading = false
                nextStep() // Move to email verification step
            }
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isLoading = false
            }
        }
    }

    func resendEmailVerification() async throws {
        try await authService.sendEmailVerification()
    }

    func checkEmailVerification() async -> Bool {
        do {
            // Reload user to get latest email verification status
            try await authService.reloadUser()

            // Return current email verification status
            return authService.isEmailVerified()
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
            }
            return false
        }
    }

    func sendPhoneVerification() async {
        isLoading = true
        authenticationError = nil

        do {
            let fullPhoneNumber = "\(countryCode)\(phoneNumber)"
            let verificationID = try await authService.sendPhoneVerification(phoneNumber: fullPhoneNumber)

            await MainActor.run {
                phoneVerificationID = verificationID
                isLoading = false
            }
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isLoading = false
            }
        }
    }

    func verifyPhoneCode(_ code: String) async {
        guard let verificationID = phoneVerificationID else {
            authenticationError = "Verification ID not found. Please request a new code."
            return
        }

        isLoading = true
        authenticationError = nil

        do {
            _ = try await authService.verifyPhoneCode(verificationID: verificationID, code: code)

            await MainActor.run {
                isLoading = false
                nextStep()
            }
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isLoading = false
            }
        }
    }

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        authenticationError = nil

        do {
            let user = try await authService.signInWithEmail(email: email, password: password)

            // Check if user has completed onboarding by fetching profile
            if let _ = try? await firestoreService.getUserProfile(userId: user.uid) {
                // User exists, navigate to completed
                await MainActor.run {
                    isLoading = false
                    skipToStep(.completed)
                }
            } else {
                // User authenticated but hasn't completed onboarding
                // Pre-fill their email and check verification status
                await MainActor.run {
                    self.email = user.email ?? ""
                    isLoading = false

                    // If email is verified, skip to full name step
                    // Otherwise, send them to email verification
                    if user.isEmailVerified {
                        skipToStep(.signUpFullName)
                    } else {
                        skipToStep(.emailVerification)
                    }
                }
            }
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isLoading = false
            }
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        authenticationError = nil

        do {
            let user = try await authService.signInWithGoogle()

            // Check if user has completed onboarding
            if let _ = try? await firestoreService.getUserProfile(userId: user.uid) {
                await MainActor.run {
                    isLoading = false
                    skipToStep(.completed)
                }
            } else {
                await MainActor.run {
                    self.email = user.email ?? ""
                    isLoading = false
                    skipToStep(.signUpFullName)
                }
            }
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isLoading = false
            }
        }
    }

    func signInWithApple(credential: AuthenticationServices.ASAuthorizationAppleIDCredential) async {
        isLoading = true
        authenticationError = nil

        do {
            let user = try await authService.signInWithApple(credential: credential)

            // Check if user has completed onboarding
            if let _ = try? await firestoreService.getUserProfile(userId: user.uid) {
                await MainActor.run {
                    isLoading = false
                    skipToStep(.completed)
                }
            } else {
                await MainActor.run {
                    self.email = user.email ?? ""
                    if let fullName = credential.fullName {
                        self.fullName = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                    }
                    isLoading = false
                    skipToStep(.signUpFullName)
                }
            }
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isLoading = false
            }
        }
    }

    func completeOnboarding() async {
        isLoading = true
        authenticationError = nil

        do {
            guard let firebaseUser = authService.getCurrentUser() else {
                throw AuthenticationError.userNotFound
            }

            // Create user profile
            let user = User(
                id: firebaseUser.uid,
                email: email,
                phoneNumber: "\(countryCode)\(phoneNumber)",
                isEmailVerified: firebaseUser.isEmailVerified,
                isPhoneVerified: authService.isPhoneVerified(),
                fullName: fullName,
                username: username,
                gender: gender,
                birthday: birthday,
                relationshipStatus: relationshipStatus,
                marriageTimeline: marriageTimeline,
                topicPriorities: topicPriorities,
                partnerId: nil,
                partnerConnectionStatus: .none,
                answerPreference: answerPreference,
                createdAt: Date(),
                updatedAt: Date(),
                photoURL: nil
            )

            // Save to Firestore
            try await firestoreService.saveUserProfile(user)

            await MainActor.run {
                isLoading = false
                skipToStep(.accountSetupLoading)
            }
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isLoading = false
            }
        }
    }

    func checkUsernameAvailability() async -> Bool {
        do {
            return try await firestoreService.isUsernameAvailable(username)
        } catch {
            return false
        }
    }
}

import AuthenticationServices
