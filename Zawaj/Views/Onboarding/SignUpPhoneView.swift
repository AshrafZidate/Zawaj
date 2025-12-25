//
//  SignUpPhoneView.swift
//  Zawaj
//
//  Created by Ashraf Zidate on 19/12/2025.
//

import SwiftUI

struct SignUpPhoneView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var showingCountryPicker = false

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Back button and progress bar - just below dynamic island
                HStack {
                    Button(action: {
                        coordinator.previousStep()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    ProgressBar(progress: coordinator.currentStep.progress)
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Content section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Phone Number")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)

                    Text("Enter your phone number")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))

                    // Phone number text field with country code
                    HStack(spacing: 12) {
                        // Country code selector
                        Button(action: {
                            showingCountryPicker = true
                        }) {
                            HStack(spacing: 6) {
                                Text(coordinator.countryCode)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        // Phone number field
                        HStack {
                            TextField("", text: $coordinator.phoneNumber, prompt: Text("Phone Number").foregroundColor(.white.opacity(0.6)))
                                .font(.body)
                                .foregroundColor(.white)
                                .textFieldStyle(.plain)
                                .keyboardType(.phonePad)

                            if !coordinator.phoneNumber.isEmpty {
                                Button {
                                    coordinator.phoneNumber = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button - just above bottom
                GlassButton(title: "Send Verification Code") {
                    Task {
                        await coordinator.sendPhoneVerification()
                        // Move to next step only if verification SMS was sent successfully
                        if coordinator.phoneVerificationID != nil {
                            coordinator.nextStep()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .disabled(coordinator.isLoading || coordinator.phoneNumber.isEmpty)
            }

            // Loading overlay
            if coordinator.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .sheet(isPresented: $showingCountryPicker) {
            CountryCodePickerView(selectedCountryCode: $coordinator.countryCode)
        }
        .alert("Verification Failed", isPresented: .constant(coordinator.authenticationError != nil)) {
            Button("OK", role: .cancel) {
                coordinator.authenticationError = nil
            }
        } message: {
            if let error = coordinator.authenticationError {
                Text(error)
            }
        }
    }
}

struct CountryCodePickerView: View {
    @Binding var selectedCountryCode: String
    @Environment(\.dismiss) var dismiss

    let countryCodes = [
        ("🇺🇸", "+1", "United States"),
        ("🇬🇧", "+44", "United Kingdom"),
        ("🇨🇦", "+1", "Canada"),
        ("🇦🇺", "+61", "Australia"),
        ("🇩🇪", "+49", "Germany"),
        ("🇫🇷", "+33", "France"),
        ("🇪🇸", "+34", "Spain"),
        ("🇮🇹", "+39", "Italy"),
        ("🇯🇵", "+81", "Japan"),
        ("🇨🇳", "+86", "China"),
        ("🇮🇳", "+91", "India"),
        ("🇧🇷", "+55", "Brazil"),
        ("🇲🇽", "+52", "Mexico"),
        ("🇦🇪", "+971", "UAE"),
        ("🇸🇦", "+966", "Saudi Arabia"),
        ("🇪🇬", "+20", "Egypt"),
        ("🇵🇰", "+92", "Pakistan"),
        ("🇹🇷", "+90", "Turkey"),
    ]

    var body: some View {
        NavigationView {
            List(countryCodes, id: \.1) { flag, code, country in
                Button(action: {
                    selectedCountryCode = code
                    dismiss()
                }) {
                    HStack {
                        Text(flag)
                            .font(.system(size: 24))
                        Text(country)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(code)
                            .foregroundColor(.secondary)
                        if selectedCountryCode == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpPhoneView()
        .environmentObject(OnboardingCoordinator())
}
