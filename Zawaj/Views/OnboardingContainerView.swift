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
            case .signUpPhone:
                SignUpPhoneView()
            case .signUpPassword:
                SignUpPasswordView()
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
            case .enableNotifications:
                EnableNotificationsView()
            case .accountSetupLoading:
                AccountSetupLoadingView()
            case .completed:
                // TODO: Navigate to main app view
                Text("Onboarding Complete!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.18, green: 0.05, blue: 0.35),
                                Color(red: 0.72, green: 0.28, blue: 0.44)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .environmentObject(coordinator)
        .animation(.easeInOut(duration: 0.3), value: coordinator.currentStep)
    }
}

#Preview {
    OnboardingContainerView()
}
