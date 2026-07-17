//
//  AIConsentGateView.swift
//  FixFly
//
//  One-time, non-skippable consent shown once before the app can be used. It turns
//  the AI data disclosure into an explicit permission step: the user must tap
//  "I Agree & Continue" before any photo or prompt is sent to a third-party AI
//  provider. Required by App Review Guidelines 5.1.1(i) / 5.1.2(i) — "obtain the
//  user's permission before sending data".
//
//  Gated in AppLoadingView via @AppStorage("ai_data_consent_v1"). The "_v1" lets us
//  re-prompt everyone if the set of providers ever materially changes.
//

import SwiftUI

struct AIConsentGateView: View {
    var onAgree: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                // Same disclosure the user can re-read any time from Settings, but
                // listing every provider (not just the one behind one template).
                AIDisclosureContent(provider: .gemini, whoText: allProvidersText)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    // Leave room for the sticky consent bar below.
                    .padding(.bottom, 200)
            }

            consentBar
        }
        .preferredColorScheme(.dark)
    }

    private var consentBar: some View {
        VStack(spacing: 12) {
            Button(action: onAgree) {
                Text("I Agree & Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Text("By continuing, you agree that the photos and prompts you submit are sent to these AI providers to create your results.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
                Link("Terms of Use", destination: LegalLinks.termsOfUse)
            }
            .font(.system(size: 12, weight: .semibold))
            .tint(.white.opacity(0.85))
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 30)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.85), .black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
