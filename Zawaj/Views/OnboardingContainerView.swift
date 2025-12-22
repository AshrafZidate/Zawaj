//
//  OnboardingContainerView.swift
//  Zawaj
//
//  Created on 2025-12-20.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var coordinator = OnboardingCoordinator()

    var body: some View {
        Group {
            switch coordinator.currentStep {
            case .welcome:
                WelcomeView()
            case .login:
                LoginView()
            case .signUpEmail:
                SignUpEmailView()
            case .signUpPassword:
                SignUpPasswordView()
            case .emailVerification:
                EmailVerificationView()
            case .signUpFullName:
                SignUpFullNameView()
            case .signUpUsername:
                SignUpUsernameView()
            case .signUpGender:
                SignUpGenderView()
            case .signUpBirthday:
                SignUpBirthdayView()
            case .signUpRelationshipStatus:
                SignUpRelationshipStatusView()
            case .signUpMarriageTimeline:
                SignUpMarriageTimelineView()
            case .signUpTopicPriorities:
                SignUpTopicPrioritiesView()
            case .signUpAddPartner:
                SignUpAddPartnerView()
            case .signUpAnswerPreference:
                SignUpAnswerPreferenceView()
            case .enableNotifications:
                EnableNotificationsView()
            case .accountSetupLoading:
                AccountSetupLoadingView()
            case .completed:
                DashboardView()
            }
        }
        .environmentObject(coordinator)
        .animation(.easeInOut(duration: 0.3), value: coordinator.currentStep)
    }
}

#Preview {
    OnboardingContainerView()
}
