//
//  AIConsentGateView.swift
//  FixFly
//
//  Just-in-time AI data-sharing consent. Shown the first time the user starts a
//  generation, right before their photo is sent to a third-party AI provider — the
//  explicit permission App Review requires under Guidelines 5.1.1(i) / 5.1.2(i).
//
//  Presented over everything by AIConsentPresenter (an overlay window), so the
//  network layer can gate on it no matter which screen triggered the generation.
//  A compact card, not a scrolling page: the full disclosure lives in Settings →
//  "How your data is used" (AIDataDisclosureView).
//

import SwiftUI

struct AIConsentGateView: View {
    var onAgree: () -> Void
    var onCancel: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed backdrop — tap outside the card to back out (no generation).
            Color.black.opacity(appeared ? 0.55 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { close(onCancel) }

            card
                .frame(maxWidth: 460)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
                .offset(y: appeared ? 0 : 60)
                .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) { appeared = true }
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, 26)

            Text("How your photos are used")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Text("To create your result, the photo and prompt you choose are sent to our AI providers to be processed.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .padding(.horizontal, 6)

            VStack(spacing: 16) {
                row(icon: "photo.on.rectangle.angled",
                    title: "What we send",
                    text: "Only the photo(s) and prompt you pick — no account or identity data.")
                row(icon: "globe",
                    title: "Who receives it",
                    text: "Google (Gemini & Veo). Some dance and motion effects use Kling AI, processed in China.")
                row(icon: "hand.raised.fill",
                    title: "Not used for training",
                    text: "Your photos are used only to make your result, never to train AI models.")
            }
            .padding(.top, 22)
            .padding(.horizontal, 4)

            Button { close(onAgree) } label: {
                Text("I Agree & Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(FixFlyGradient.linear, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 26)

            HStack(spacing: 7) {
                Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
                dot
                Link("Terms", destination: LegalLinks.termsOfUse)
                dot
                Button("Not now") { close(onCancel) }
            }
            .font(.system(size: 12, weight: .semibold))
            .tint(.white.opacity(0.55))
            .foregroundStyle(.white.opacity(0.55))
            .padding(.top, 15)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
    }

    private var dot: some View {
        Text("·").foregroundStyle(.white.opacity(0.3))
    }

    private func row(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(FixFlyGradient.accent)
                .frame(width: 24, height: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    /// Animate the card out, then run the real action so the continuation resolves
    /// after the dismissal instead of snapping away.
    private func close(_ action: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.22)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: action)
    }
}
