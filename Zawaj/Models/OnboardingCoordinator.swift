//
//  OnboardingCoordinator.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case login
    case signUpEmail
    case signUpPhone
    case signUpPassword
    case signUpFullName
    case signUpUsername
    case signUpGender
    case signUpBirthday
    case signUpRelationshipStatus
    case signUpMarriageTimeline
    case signUpTopicPriorities
    case signUpAddPartner
    case enableNotifications
    case accountSetupLoading
    case completed

    var progress: Double {
        // Calculate progress based on step position
        // Welcome, login, accountSetupLoading, and completed don't count towards progress
        switch self {
        case .welcome:
            return 0.0
        case .login:
            return 0.0
        case .signUpEmail:
            return 0.08
        case .signUpPhone:
            return 0.17
        case .signUpPassword:
            return 0.25
        case .signUpFullName:
            return 0.33
        case .signUpUsername:
            return 0.42
        case .signUpGender:
            return 0.50
        case .signUpBirthday:
            return 0.58
        case .signUpRelationshipStatus:
            return 0.67
        case .signUpMarriageTimeline:
            return 0.75
        case .signUpTopicPriorities:
            return 0.83
        case .signUpAddPartner:
            return 0.92
        case .enableNotifications:
            return 1.0
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
    @Published var notificationsEnabled: Bool = false

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
        notificationsEnabled = false
    }
}
