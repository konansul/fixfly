//
//  GoogleSignInManager.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import UIKit
import Foundation
import Combine
import GoogleSignIn

struct GoogleAuthResult {
    let idToken: String
    let accessToken: String
    let email: String?
    let fullName: String?
}

@MainActor
final class GoogleSignInManager: ObservableObject {

    static let shared = GoogleSignInManager()
    private init() {}

    func signIn() async -> Result<GoogleAuthResult, Error> {
        do {
            guard let presentingVC = UIApplication.shared.topMostViewController() else {
                throw NSError(
                    domain: "FixFly.Google",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No presenting view controller"]
                )
            }

            guard
                let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
                !clientID.isEmpty
            else {
                throw NSError(
                    domain: "FixFly.Google",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Missing GIDClientID in Info.plist"]
                )
            }

            // (опционально) server client id для бэка, если ты его создал
            let serverClientID = Bundle.main.object(forInfoDictionaryKey: "GIDServerClientID") as? String

    
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(
                clientID: clientID,
                serverClientID: serverClientID
            )

            let signInResult = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<GIDSignInResult, Error>) in
                GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
                    if let error = error {
                        cont.resume(throwing: error)
                        return
                    }
                    guard let result = result else {
                        cont.resume(throwing: NSError(
                            domain: "FixFly.Google",
                            code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "Google Sign-In returned empty result"]
                        ))
                        return
                    }
                    cont.resume(returning: result)
                }
            }

            let user = signInResult.user

            guard let idToken = user.idToken?.tokenString, !idToken.isEmpty else {
                throw NSError(
                    domain: "FixFly.Google",
                    code: -4,
                    userInfo: [NSLocalizedDescriptionKey: "Missing idToken"]
                )
            }

            let out = GoogleAuthResult(
                idToken: idToken,
                accessToken: user.accessToken.tokenString,
                email: user.profile?.email,
                fullName: user.profile?.name
            )

            return .success(out)

        } catch {
            return .failure(error)
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}

// MARK: - Top-most VC helper (фикс)
private extension UIApplication {
    func topMostViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC: UIViewController? = {
            if let base { return base }
            let scene = connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first(where: { $0.activationState == .foregroundActive })
            let window = scene?.windows.first(where: { $0.isKeyWindow })
            return window?.rootViewController
        }()

        guard let baseVC else { return nil }

        if let nav = baseVC as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        if let presented = baseVC.presentedViewController {
            return topMostViewController(base: presented)
        }
        return baseVC
    }
}
