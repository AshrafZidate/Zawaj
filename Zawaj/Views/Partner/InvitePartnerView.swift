//
//  InvitePartnerView.swift
//  Zawaj
//
//  Created on 2025-12-22.
//

import SwiftUI

struct InvitePartnerView: View {
    @Environment(\.dismiss) var dismiss

    @State private var inviteMethod: InviteMethod = .link

    enum InviteMethod {
        case link
        case email
        case sms
    }

    var body: some View {
        NavigationView {
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
                        VStack(spacing: 12) {
                            Image(systemName: "envelope.badge.person.crop")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.8))

                            Text("Invite your partner to Zawāj")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("Share Zawāj with someone special and start your journey together")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // Invite Options
                        VStack(spacing: 16) {
                            // Share Link
                            InviteOptionCard(
                                icon: "link",
                                title: "Share Invite Link",
                                description: "Copy your unique invite link to share",
                                action: {
                                    shareInviteLink()
                                }
                            )

                            // Email Invite
                            InviteOptionCard(
                                icon: "envelope",
                                title: "Send Email Invite",
                                description: "Send an invitation via email",
                                action: {
                                    sendEmailInvite()
                                }
                            )

                            // SMS Invite
                            InviteOptionCard(
                                icon: "message",
                                title: "Send SMS Invite",
                                description: "Send an invitation via text message",
                                action: {
                                    sendSMSInvite()
                                }
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Invite Partner")
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

    private func shareInviteLink() {
        // TODO: Generate and share invite link
        let inviteLink = "https://zawaj.app/invite/\(UUID().uuidString)"
        UIPasteboard.general.string = inviteLink

        // Show share sheet
        let activityVC = UIActivityViewController(
            activityItems: [
                "Join me on Zawāj! Let's explore our compatibility together. \(inviteLink)"
            ],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func sendEmailInvite() {
        // TODO: Open email composer with pre-filled invitation
        let emailSubject = "Join me on Zawāj"
        let emailBody = "I'd love for you to join me on Zawāj, an app for couples exploring marriage. Let's discover our compatibility together!"

        let urlString = "mailto:?subject=\(emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func sendSMSInvite() {
        // TODO: Open messages app with pre-filled invitation
        let smsBody = "Join me on Zawāj! Let's explore our compatibility together. Download the app: https://zawaj.app"

        let urlString = "sms:&body=\(smsBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct InviteOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    InvitePartnerView()
}
