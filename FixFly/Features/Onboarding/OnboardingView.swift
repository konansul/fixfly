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
                        title: "Hundreds of styles and templates",
                        subtitle: "Pick a look, add your photo, and let AI do the magic."
                    ).tag(1)

                    textBlock(
                        title: "Save your creations",
                        subtitle: "Sign in with Apple to keep your coins and creations across all your devices."
                    ).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 220)
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
            VStack(spacing: 14) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .clipShape(Capsule())

                Button("Maybe later") { finish() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
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
            await AuthStore.shared.loginWithApple(
                identityToken: token,
                fullName: name.isEmpty ? nil : name
            )
            finish()
        }
    }

    private func finish() {
        onFinish()
    }
}
