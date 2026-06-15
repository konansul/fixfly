//  WelcomeBonusView.swift
//  FixFly
//
//  One-time "welcome coins" modal shown to brand-new users. The amount comes
//  from the backend (signup bonus), so this only appears when the bonus is
//  enabled (> 0) — when the backend sets it to 0, nothing is presented.
//

import SwiftUI

struct WelcomeBonusView: View {
    let coins: Int
    var onClaim: () -> Void

    @State private var coinScale: CGFloat = 0.6
    @State private var coinRotation: Double = 0
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(FixFlyGradient.linear)
                    .scaleEffect(coinScale)
                    .rotation3DEffect(.degrees(coinRotation), axis: (x: 0, y: 1, z: 0))
                    .shadow(color: FixFlyGradient.accent.opacity(0.5), radius: 24)

                VStack(spacing: 8) {
                    Text("Welcome gift!")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)

                    Text("\(coins) Coins")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(FixFlyGradient.linear)

                    Text("We've added \(coins) coins to your wallet so you can start creating right away.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    onClaim()
                } label: {
                    Text("Start creating")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Capsule().fill(FixFlyGradient.linear))
                }
                .buttonStyle(.plain)
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
            AppAnalytics.track(.screen(name: "WelcomeBonus"))
        }
    }
}
