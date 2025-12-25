//
//  AddPartnerView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct AddPartnerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AddPartnerViewModel()

    @State private var partnerUsername: String = ""
    @State private var showingErrorAlert: Bool = false
    @State private var showingSuccessAlert: Bool = false

    // Share content for invite
    private let inviteMessage = "Download the Zawaj app so we can get to know each other better for marriage!"
    private let appStoreLink = "https://apps.apple.com/app/zawaj" // TODO: Replace with actual App Store link

    private var shareContent: String {
        return "\(inviteMessage)\n\n\(appStoreLink)"
    }

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()

                VStack(spacing: 0) {
                    // Content section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add your partner")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)

                        Text("Add your partner so you can begin your Zawāj journey together.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))

                        // Partner username text field
                        HStack {
                            TextField("", text: $partnerUsername, prompt: Text("Partner's username or email").foregroundColor(.white.opacity(0.6)))
                                .font(.body)
                                .foregroundColor(.white)
                                .textFieldStyle(.plain)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()

                            if !partnerUsername.isEmpty {
                                Button {
                                    partnerUsername = ""
                                    viewModel.clearSearch()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .glassEffect(.clear)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Spacer()

                    // Action buttons
                    VStack(spacing: 16) {
                        GlassButtonPrimary(title: "Send partner request", icon: "paperplane.fill") {
                            Task {
                                await viewModel.searchAndSendRequest(query: partnerUsername)
                                if viewModel.error != nil {
                                    showingErrorAlert = true
                                } else if viewModel.requestSent {
                                    showingSuccessAlert = true
                                }
                            }
                        }
                        .disabled(partnerUsername.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSearching)
                        .opacity(partnerUsername.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)

                        ShareLink(item: shareContent) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                Text("Invite partner to Zawāj")
                                    .font(.body.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .tint(nil)
                        .buttonStyle(.glass)
                        .glassEffect(.clear)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Add Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.18, green: 0.05, blue: 0.35),
                        Color(red: 0.72, green: 0.28, blue: 0.44)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                for: .navigationBar
            )
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Unable to Send Request", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "An error occurred")
            }
            .alert("Request Sent", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your partner request has been sent successfully!")
            }
        }
    }
}

#Preview {
    AddPartnerView()
}
