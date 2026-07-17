//
//  AIDataDisclosureView.swift
//  FixFly
//
//  In-app disclosure of what user data is sent to our third-party AI providers
//  (Google Cloud Vertex AI, and Kling AI / Kuaishou for motion templates) and what
//  is not. Surfaced from Settings and from the generation screens so users can
//  check, inside the app, exactly what is shared and with whom (App Review 5.1.1).
//
//  The same content backs the one-time consent gate (AIConsentGateView), which
//  turns this disclosure into an explicit "I Agree before your photo is sent" step
//  — the permission App Review requires under Guidelines 5.1.1(i) / 5.1.2(i).
//

import SwiftUI

/// Who actually processes a generation. Not every template goes to Google: the
/// motion-control dances are sent to Kling (Kuaishou, China), and saying "Google
/// Veo" over one of those would be a false disclosure.
enum AIProvider: String {
    case gemini
    case veo
    case kling

    var isGoogle: Bool { self != .kling }

    /// What the chip reads.
    var label: String {
        switch self {
        case .gemini: return "Google Gemini"
        case .veo:    return "Google Veo"
        case .kling:  return "Kling AI"
        }
    }

    /// Who receives the photo, for the "Who processes it" card.
    var processorText: String {
        switch self {
        case .gemini:
            return "Google Cloud (Vertex AI). Your photo and prompt are processed by Google's Gemini image model."
        case .veo:
            return "Google Cloud (Vertex AI). Your photo and prompt are processed by Google's Veo video model."
        case .kling:
            return "Kling AI, operated by Kuaishou Technology. This template copies a dancer's movement onto your photo, which only Kling can do, so your photo is processed on their servers rather than Google's."
        }
    }
}

/// Text for the "Who processes it" card when disclosing every provider at once
/// (the one-time consent gate, which isn't tied to a single template).
let allProvidersText =
    "For most photos and videos, Google Cloud (Vertex AI) — Google's Gemini and Veo models. "
    + "For certain motion and dance video effects, Kling AI, operated by Kuaishou Technology in China, "
    + "because only Kling can copy a reference movement onto your photo."

/// Compact, tappable chip shown next to a generation action: the provider's mark +
/// the model that processes the request. Tapping opens the full disclosure.
/// Self-contained (owns its sheet state) so screens can drop it in without wiring.
struct AIDisclosureFootnote: View {
    var provider: AIProvider
    @State private var show = false

    var body: some View {
        Button { show = true } label: {
            HStack(spacing: 5) {
                if provider.isGoogle {
                    Image("ic_google")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                } else {
                    Image(systemName: "cpu")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(provider.label)
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
            AIDataDisclosureView(provider: provider)
        }
    }
}

struct AIDataDisclosureView: View {
    /// Settings opens this with no template in hand; Gemini is the common case.
    var provider: AIProvider = .gemini
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.fixFlyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    AIDisclosureContent(provider: provider)
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
}

/// The scrollable body of the AI data disclosure. Shared by the read-only sheet
/// (Settings + the generation footnote) and the one-time consent gate, so the copy
/// the user agrees to and the copy they can re-read later never drift apart.
struct AIDisclosureContent: View {
    var provider: AIProvider = .gemini
    /// Override the "Who processes it" card (the consent gate lists every provider,
    /// not just the one behind a single template).
    var whoText: String? = nil

    var body: some View {
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
                text: whoText ?? provider.processorText
            )

            card(
                icon: "lock.shield",
                title: "What we don't send",
                text: "No account or identity data — no name, email, Apple ID or device identifiers are sent to the AI providers."
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
