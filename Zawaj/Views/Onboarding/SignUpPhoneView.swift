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
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.18, green: 0.05, blue: 0.35), // #2e0d5a
                    Color(red: 0.72, green: 0.28, blue: 0.44)  // #b7486f
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
                        TextField("", text: $coordinator.phoneNumber, prompt: Text("Phone Number").foregroundColor(.secondary))
                            .font(.body)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .keyboardType(.phonePad)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Continue button - just above bottom
                GlassmorphicButton(title: "Continue") {
                    coordinator.nextStep()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showingCountryPicker) {
            CountryCodePickerView(selectedCountryCode: $coordinator.countryCode)
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
