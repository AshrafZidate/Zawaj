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

                    // Send partner request button
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
