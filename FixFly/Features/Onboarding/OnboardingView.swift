//
//  OnboardingView.swift
//  FixFly
//
//  First-launch onboarding: 3 pages over the shared TemplateVideoWall.
//

import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    var onFinish: () -> Void

    @ObservedObject private var auth = AuthStore.shared
    @ObservedObject private var config = AppConfigStore.shared

    @State private var page = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TemplateVideoWall()
                .ignoresSafeArea()

            // Scrim so the text stays legible over the wall.
            LinearGradient(
                colors: [.black.opacity(0.25), .clear, .black.opacity(0.55), .black.opacity(0.92), .black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if page < 2 {
                        Button("Skip") { finish() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(height: 30)
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                TabView(selection: $page) {
                    textBlock(
                        title: "Create stunning AI photos and videos",
                        subtitle: "Turn your photos into cinematic art in seconds."
                    ).tag(0)

                    textBlock(
                        title: "Viral trends, dances and more",
                        subtitle: "Make your face dance, hit the trends, and try hundreds of styles — just add your photo."
                    ).tag(1)

                    Group {
                        if config.signupBonusCoins > 0 {
                            bonusBlock(coins: config.signupBonusCoins)
                        } else {
                            // Bonus disabled on the backend — fall back to the
                            // original, reward-free copy.
                            textBlock(
                                title: "Save your creations",
                                subtitle: "Sign in with Apple to keep your coins and creations across all your devices."
                            )
                        }
                    }.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 250)
                .animation(.easeInOut, value: page)

                dots
                    .padding(.vertical, 18)

                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .onAppear { AppAnalytics.track(.screen(name: "Onboarding")) }
    }

    private func textBlock(title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    /// Final page — leads with the reward so guests actually know signing in is
    /// worth it (the old copy only mentioned "keep your coins").
    private func bonusBlock(coins: Int) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("\(coins) FREE COINS")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(0.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(FixFlyGradient.linear))
            .shadow(color: FixFlyGradient.accent.opacity(0.5), radius: 12)

            Text("Sign in and get \(coins) free coins")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text("Enough to create your first AI photo — on us. Your coins and creations stay saved across all your devices.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(.white.opacity(i == page ? 0.95 : 0.3))
                    .frame(width: i == page ? 22 : 7, height: 7)
            }
        }
        .animation(.easeInOut, value: page)
    }

    @ViewBuilder
    private var bottomControls: some View {
        if page < 2 {
            Button {
                withAnimation { page += 1 }
            } label: {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        } else {
            VStack(spacing: 10) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .clipShape(Capsule())
                .disabled(auth.isLoading)
                .opacity(auth.isLoading ? 0.5 : 1)

                if auth.isLoading {
                    ProgressView().tint(.white)
                } else if let error = auth.errorText {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                Button("Maybe later") { finish() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .disabled(auth.isLoading)
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            return  // cancelled / no token — stay on the page
        }
        let name = [cred.fullName?.givenName, cred.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        Task {
            await auth.loginWithApple(
                identityToken: token,
                fullName: name.isEmpty ? nil : name
            )
            // Success → finish onboarding. On failure errorText is shown and we
            // stay so the user can retry or skip.
            if auth.isAuthed { finish() }
        }
    }

    private func finish() {
        onFinish()
    }
}
