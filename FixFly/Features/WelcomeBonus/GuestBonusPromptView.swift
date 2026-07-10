//
//  GuestBonusPromptView.swift
//  FixFly
//
//  One-time promo shown to GUESTS (users who skipped sign-in and are browsing).
//  It advertises the free signup coins up front — the old flow only revealed the
//  bonus AFTER signing in (WelcomeBonusView), so guests never knew it existed.
//  Tapping "Continue with Apple" triggers the native sign-in sheet directly.
//

import SwiftUI

struct GuestBonusPromptView: View {
    let coins: Int
    var onSignIn: () -> Void
    var onDismiss: () -> Void

    @State private var coinScale: CGFloat = 0.6
    @State private var coinRotation: Double = 0
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 22) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(.yellow)
                    .scaleEffect(coinScale)
                    .rotation3DEffect(.degrees(coinRotation), axis: (x: 0, y: 1, z: 0))
                    .shadow(color: .yellow.opacity(0.4), radius: 24)

                VStack(spacing: 8) {
                    Text("Claim your free coins")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(coins) Coins")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(FixFlyGradient.linear)

                    Text("Sign in with Apple to get \(coins) free coins — enough to create your first AI photo, on us.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 10) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSignIn()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Continue with Apple")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(.white))
                    }
                    .buttonStyle(.plain)

                    Button("Maybe later") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 4)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appear = true
                coinScale = 1
            }
            withAnimation(.easeInOut(duration: 0.9).delay(0.1)) {
                coinRotation = 360
            }
            AppAnalytics.track(.screen(name: "GuestBonusPrompt"))
        }
    }

    private func dismiss() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onDismiss()
    }
}
