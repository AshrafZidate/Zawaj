//
//  DebugQuestionBankView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI
import Combine

struct DebugQuestionBankView: View {
    @StateObject private var viewModel = DebugQuestionBankViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.18, green: 0.05, blue: 0.35),
                    Color(red: 0.72, green: 0.28, blue: 0.44)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.8))

                        Text("Question Bank Tools")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)

                        Text("Development utilities")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    // Question Bank Info
                    if let questionBank = viewModel.questionBank {
                        VStack(alignment: .leading, spacing: 16) {
                            InfoRow(label: "Total Questions", value: "\(questionBank.questions.count)")
                            InfoRow(label: "Version", value: questionBank.metadata.version)
                            InfoRow(label: "Topics", value: "\(questionBank.metadata.topics.count)")

                            Divider()
                                .background(Color.white.opacity(0.3))

                            Text("Questions Preview")
                                .font(.headline)
                                .foregroundColor(.white)

                            ForEach(questionBank.questions.prefix(3), id: \.id) { question in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(question.topic)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(question.questionText)
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    // Upload Button
                    Button(action: {
                        Task {
                            await viewModel.uploadToFirestore()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if viewModel.isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 20))
                            }

                            Text(viewModel.isUploading ? "Uploading..." : "Upload to Firestore")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.isUploading ? Color.gray : Color(red: 0.94, green: 0.26, blue: 0.42),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .disabled(viewModel.isUploading)

                    // Status Messages
                    if let statusMessage = viewModel.statusMessage {
                        Text(statusMessage)
                            .font(.body)
                            .foregroundColor(viewModel.uploadSuccess ? .green : .white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let error = viewModel.error {
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Warning
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("Warning")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }

                        Text("Only upload the question bank once. Running this multiple times will overwrite existing questions in Firestore.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Debug Tools")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        .onAppear {
            viewModel.loadQuestionBank()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.body.weight(.medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - ViewModel

class DebugQuestionBankViewModel: ObservableObject {
    @Published var questionBank: QuestionBankService.QuestionBankJSON?
    @Published var isUploading: Bool = false
    @Published var statusMessage: String?
    @Published var error: String?
    @Published var uploadSuccess: Bool = false

    private let questionBankService = QuestionBankService()

    func loadQuestionBank() {
        questionBank = questionBankService.loadQuestionBankFromJSON()

        if questionBank == nil {
            error = "Failed to load question_bank.json. Make sure it's added to the Xcode project."
        }
    }

    func uploadToFirestore() async {
        await MainActor.run {
            isUploading = true
            statusMessage = nil
            error = nil
            uploadSuccess = false
        }

        do {
            try await questionBankService.uploadQuestionBankToFirestore()

            await MainActor.run {
                uploadSuccess = true
                statusMessage = "✅ Successfully uploaded \(questionBank?.questions.count ?? 0) questions to Firestore!"
                isUploading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Upload failed: \(error.localizedDescription)"
                isUploading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        DebugQuestionBankView()
    }
}
