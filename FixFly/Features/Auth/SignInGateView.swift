//
//  SignInGateView.swift
//  FixFly
//
//  Shown when a guest tries a value action (Generate / Buy). Sign in with Apple
//  is the only identity, so we create the backend account here on demand.
//

import SwiftUI
import AuthenticationServices

struct SignInGateView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text("Sign in to continue")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("Sign in with Apple to generate, buy coins, and keep your balance across devices.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 14) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .clipShape(Capsule())

                Button("Maybe later") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            return  // cancelled / no token — stay on the sheet
        }
        let name = [cred.fullName?.givenName, cred.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        Task {
            await auth.loginWithApple(
                identityToken: token,
                fullName: name.isEmpty ? nil : name
            )
            if auth.isAuthed { dismiss() }
        }
    }
}

private struct SignInGateModifier: ViewModifier {
    @ObservedObject var auth: AuthStore

    func body(content: Content) -> some View {
        content.sheet(isPresented: $auth.presentSignIn) {
            SignInGateView().environmentObject(auth)
        }
    }
}

extension View {
    /// Presents the Sign in with Apple gate whenever `AuthStore.requireSignIn()`
    /// is triggered. Attach at every presentation context that hosts a value
    /// action — the tab root, and modal surfaces above it (e.g. the paywall),
    /// since a sheet on the root cannot appear above a fullScreenCover.
    func signInGate(_ auth: AuthStore = .shared) -> some View {
        modifier(SignInGateModifier(auth: auth))
    }
}
