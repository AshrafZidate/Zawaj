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

    @State private var searchText: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                GradientBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Search Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Find your partner")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)

                            Text("Search by username or email")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))

                            // Search Bar
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white.opacity(0.6))

                                TextField("", text: $searchText, prompt: Text("@username or email").foregroundColor(.white.opacity(0.5)))
                                    .foregroundColor(.white)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()

                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                        viewModel.clearSearch()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                            // Search Button
                            Button(action: {
                                Task {
                                    await viewModel.searchForPartner(query: searchText)
                                }
                            }) {
                                HStack {
                                    if viewModel.isSearching {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Search")
                                            .font(.body.weight(.medium))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Color(red: 0.94, green: 0.26, blue: 0.42),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            }
                            .disabled(searchText.isEmpty || viewModel.isSearching)
                            .opacity(searchText.isEmpty || viewModel.isSearching ? 0.5 : 1.0)
                        }
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))

                        // Search Results
                        if let user = viewModel.searchResult {
                            PartnerSearchResultCard(
                                user: user,
                                isRequestSent: viewModel.requestSent,
                                onSendRequest: {
                                    Task {
                                        await viewModel.sendPartnerRequest(to: user)
                                    }
                                }
                            )
                        }

                        // Error Message
                        if let error = viewModel.error {
                            Text(error)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Success Message
                        if viewModel.requestSent {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)

                                Text("Partner request sent successfully!")
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
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
        }
    }
}

#Preview {
    AddPartnerView()
}
