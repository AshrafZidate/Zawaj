//
//  DebugQuestionBankView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//
//  DEPRECATED: Question bank upload is now handled via Node.js script (upload-questions.js)
//  This view is kept for viewing Firestore data and debugging purposes.
//

import SwiftUI
import Combine

struct DebugQuestionBankView: View {
    @StateObject private var viewModel = DebugQuestionBankViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            GradientBackground()

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

                        Text("View Firestore data")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    // Stats from Firestore
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            InfoRow(label: "Topics", value: "\(viewModel.topicCount)")
                            InfoRow(label: "Subtopics", value: "\(viewModel.subtopicCount)")
                            InfoRow(label: "Questions", value: "\(viewModel.questionCount)")

                            if !viewModel.topics.isEmpty {
                                Divider()
                                    .background(Color.white.opacity(0.3))

                                Text("Topics")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                ForEach(viewModel.topics) { topic in
                                    HStack {
                                        Text("\(topic.order).")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        Text(topic.name)
                                            .font(.body)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if !topic.isRankable {
                                            Text("(Non-rankable)")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            if !viewModel.sampleQuestions.isEmpty {
                                Divider()
                                    .background(Color.white.opacity(0.3))

                                Text("Sample Questions")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                ForEach(viewModel.sampleQuestions) { question in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Q\(question.id)")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(.white.opacity(0.6))
                                            Text(question.questionType == .singleChoice ? "Single" : "Multi")
                                                .font(.caption)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    question.questionType == .singleChoice ?
                                                    Color.blue.opacity(0.3) : Color.purple.opacity(0.3),
                                                    in: Capsule()
                                                )
                                                .foregroundColor(.white)
                                        }
                                        Text(question.questionText)
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    // Refresh Button
                    Button(action: {
                        Task {
                            await viewModel.loadFromFirestore()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20))

                            Text("Refresh from Firestore")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Color(red: 0.94, green: 0.26, blue: 0.42),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }

                    if let error = viewModel.error {
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Upload Info")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }

                        Text("Question bank data is uploaded via the Node.js script at /Resources/upload-questions.js. Run 'node upload-questions.js' from the Resources directory.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
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
            Task {
                await viewModel.loadFromFirestore()
            }
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
    @Published var topics: [Topic] = []
    @Published var sampleQuestions: [Question] = []
    @Published var topicCount: Int = 0
    @Published var subtopicCount: Int = 0
    @Published var questionCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let questionBankService = QuestionBankService()

    func loadFromFirestore() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            // Fetch topics
            let fetchedTopics = try await questionBankService.fetchAllTopics()

            // Fetch subtopic count
            var totalSubtopics = 0
            for topic in fetchedTopics {
                let subtopics = try await questionBankService.fetchSubtopics(forTopicId: topic.id)
                totalSubtopics += subtopics.count
            }

            // Fetch sample questions from first subtopic
            var sampleQs: [Question] = []
            if let firstTopic = fetchedTopics.first {
                let subtopics = try await questionBankService.fetchSubtopics(forTopicId: firstTopic.id)
                if let firstSubtopic = subtopics.first {
                    sampleQs = try await questionBankService.fetchQuestions(forSubtopicId: firstSubtopic.id, gender: nil)
                    sampleQs = Array(sampleQs.prefix(3))
                }
            }

            // Get total question count (estimate from first few subtopics)
            var totalQuestions = 0
            for topic in fetchedTopics.prefix(3) {
                let subtopics = try await questionBankService.fetchSubtopics(forTopicId: topic.id)
                for subtopic in subtopics {
                    let questions = try await questionBankService.fetchQuestions(forSubtopicId: subtopic.id, gender: nil)
                    totalQuestions += questions.count
                }
            }
            // Extrapolate for remaining topics
            if fetchedTopics.count > 3 {
                totalQuestions = totalQuestions * fetchedTopics.count / 3
            }

            await MainActor.run {
                self.topics = fetchedTopics
                self.sampleQuestions = sampleQs
                self.topicCount = fetchedTopics.count
                self.subtopicCount = totalSubtopics
                self.questionCount = totalQuestions
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        DebugQuestionBankView()
    }
}
