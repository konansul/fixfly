//
//  AppleSignInCoordinator.swift
//  FixFly
//
//  Triggers the native Sign in with Apple sheet programmatically (from code,
//  not a SignInWithAppleButton) so a value action — e.g. tapping Buy — can
//  bring up registration directly, without an intermediate gate screen.
//

import Foundation
import AuthenticationServices
import UIKit

@MainActor
final class AppleSignInCoordinator: NSObject {
    static let shared = AppleSignInCoordinator()
    private override init() {}

    struct Credentials {
        let identityToken: String
        let fullName: String?
    }

    private var completion: ((Credentials?) -> Void)?

    /// Presents the system Sign in with Apple sheet. `completion` gets the
    /// credentials on success, or nil on cancel/failure.
    func start(_ completion: @escaping (Credentials?) -> Void) {
        self.completion = completion

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func finish(_ credentials: Credentials?) {
        let cb = completion
        completion = nil
        cb?(credentials)
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = cred.identityToken,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            Task { @MainActor in self.finish(nil) }
            return
        }
        let name = [cred.fullName?.givenName, cred.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        Task { @MainActor in
            self.finish(Credentials(identityToken: token, fullName: name.isEmpty ? nil : name))
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // Cancellation and real errors both end with no credentials.
        Task { @MainActor in self.finish(nil) }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            return scene?.keyWindow ?? ASPresentationAnchor()
        }
    }
}
