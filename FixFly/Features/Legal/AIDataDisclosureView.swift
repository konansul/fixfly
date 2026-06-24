//
//  AIDataDisclosureView.swift
//  FixFly
//
//  In-app disclosure of what user data is sent to our third-party AI provider
//  (Google Cloud Vertex AI) and what is not. Surfaced from Settings and from the
//  generation screens so users can check, inside the app, exactly what is shared
//  and with whom (App Review Guideline 2.1).
//

import SwiftUI

/// Compact, tappable chip shown next to a generation action: the Google logo +
/// the model that processes the request ("Google Gemini" for images, "Google
/// Veo" for video). Tapping opens the full disclosure. Self-contained (owns its
/// sheet state) so screens can drop it in without extra wiring.
struct AIDisclosureFootnote: View {
    /// The Google model used for this generation, e.g. "Gemini" or "Veo".
    var model: String
    @State private var show = false

    var body: some View {
        Button { show = true } label: {
            HStack(spacing: 5) {
                Image("ic_google")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 13, height: 13)

                Text("Google \(model)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                Image(systemName: "info.circle")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $show) {
            AIDataDisclosureView()
        }
    }
}

struct AIDataDisclosureView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.fixFlyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {

                        header

                        card(
                            icon: "paperplane",
                            title: "What we send",
                            text: "Only the content you choose for a generation: the photo(s) you select and the text prompt you type."
                        )

                        card(
                            icon: "cpu",
                            title: "Who processes it",
                            text: "Google Cloud (Vertex AI) — the only third-party AI provider we use. Images are generated with Google's Gemini model and videos with Google's Veo model."
                        )

                        card(
                            icon: "lock.shield",
                            title: "What we don't send",
                            text: "No account or identity data — no name, email, Apple ID or device identifiers are sent to Google."
                        )

                        card(
                            icon: "hand.raised",
                            title: "Not used for training",
                            text: "Your photos and prompts are used solely to produce the result you requested. They are not used by us to train any models."
                        )

                        Button {
                            UIApplication.shared.open(LegalLinks.privacyPolicy)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Read the full Privacy Policy")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .foregroundStyle(.white)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Data & AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.white)

            Text("How your data is used")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("FixFly uses AI to create your photos and videos. Here's exactly what leaves your device and where it goes.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    private func card(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
