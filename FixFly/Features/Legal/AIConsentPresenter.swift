//
//  AIConsentPresenter.swift
//  FixFly
//
//  Bridges the just-in-time AI consent gate to the network layer. The three photo
//  upload methods in MultipartAPI call `await AIConsentPresenter.shared.ensure()`
//  right before sending — so every generation flow (photo, video, templates, duo,
//  photoshoot, and any added later) is covered by construction. On first use it
//  presents AIConsentGateView in an overlay window (above any sheet) and suspends
//  until the user decides.
//
//  Consent is remembered in UserDefaults("ai_data_consent_v1"); the "_v1" lets us
//  re-prompt everyone if the set of AI providers ever materially changes.
//

import UIKit
import SwiftUI

@MainActor
final class AIConsentPresenter {
    static let shared = AIConsentPresenter()
    private init() {}

    static let consentKey = "ai_data_consent_v1"

    var hasConsented: Bool { UserDefaults.standard.bool(forKey: Self.consentKey) }

    private var window: UIWindow?
    private var pending: [CheckedContinuation<Void, Error>] = []

    /// Call immediately before a user photo is sent to an AI provider. Returns once
    /// the user has agreed (now or on a previous run). Throws `CancellationError` if
    /// they back out — callers treat that as a silent no-op, no error shown.
    func ensure() async throws {
        if hasConsented { return }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            pending.append(cont)
            if window == nil { present() }
        }
    }

    private func present() {
        guard let scene = Self.foregroundScene() else {
            resolve(.failure(CancellationError()))
            return
        }
        let gate = AIConsentGateView(
            onAgree: { [weak self] in
                UserDefaults.standard.set(true, forKey: Self.consentKey)
                self?.resolve(.success(()))
            },
            onCancel: { [weak self] in
                self?.resolve(.failure(CancellationError()))
            }
        )

        let host = UIHostingController(rootView: gate)
        host.view.backgroundColor = .clear
        host.overrideUserInterfaceStyle = .dark

        let win = UIWindow(windowScene: scene)
        win.rootViewController = host
        win.backgroundColor = .clear
        win.windowLevel = .alert + 1
        win.makeKeyAndVisible()
        window = win
    }

    private func resolve(_ result: Result<Void, Error>) {
        window?.isHidden = true
        window = nil
        let waiting = pending
        pending.removeAll()
        for cont in waiting {
            switch result {
            case .success:            cont.resume()
            case .failure(let error): cont.resume(throwing: error)
            }
        }
    }

    private static func foregroundScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}
