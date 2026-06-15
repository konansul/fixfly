//
//  AuthStore.swift
//  FixFly
//

import Foundation
import Combine

@MainActor
final class AuthStore: ObservableObject {

    static let shared = AuthStore()

    @Published var user: BackendUserDTO?
    @Published var isLoading = false
    @Published var errorText: String?
    /// Set when a brand-new user just received welcome coins — the UI presents
    /// the welcome-bonus modal once and then clears it. nil / 0 = no modal.
    @Published var pendingSignupBonus: Int?
    /// Drives the Sign in with Apple gate. Set by `requireSignIn()` when a guest
    /// tries a value action (Generate / Buy); the app root presents the sheet.
    @Published var presentSignIn = false

    private init() {}

    var isAuthed: Bool {
        TokenStore.shared.accessToken != nil
    }

    func bootstrap() async {
        errorText = nil

        // Identity is Sign in with Apple only — there is no anonymous account.
        // A guest (no token) simply browses; a backend account is created lazily
        // when they first sign in (gated at a value action).
        guard isAuthed else { return }

        do {
            try await refreshMe()
            await WalletManager.shared.refreshBalance()
            // Returning Apple user (e.g. new device / relaunch) — re-claim any
            // active subscription so its renewal coins map to this account.
            await reclaimEntitlements()
        } catch {
            // Token invalid — drop to guest state.
            TokenStore.shared.clear()
            user = nil
            WalletManager.shared.clear()
        }
    }

    func loginWithApple(identityToken: String, fullName: String?) async {
        guard !isLoading else { return }

        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let dto = try await AuthAPI.shared.loginWithApple(identityToken: identityToken, fullName: fullName)
            self.user = dto.user
            AppAnalytics.track(.signInWithApple)

            if dto.signupBonusGranted > 0 {
                self.pendingSignupBonus = dto.signupBonusGranted
            }

            try? await refreshMe()
            await WalletManager.shared.refreshBalance()

            // Re-claim any active subscription under this account so the backend
            // re-points ownership and renewals start crediting coins here.
            await reclaimEntitlements()

            // User may have switched (returning user on a new device) — re-register
            // the device token under the resolved account.
            PushService.shared.onAuthChanged()
        } catch {
            errorText = error.localizedDescription
        }
    }

    /// Gate for value actions. Returns true if already signed in; otherwise
    /// triggers the Sign in with Apple sheet and returns false.
    @discardableResult
    func requireSignIn() -> Bool {
        if isAuthed { return true }
        presentSignIn = true
        return false
    }

    func refreshMe() async throws {
        let me = try await AuthAPI.shared.me()
        self.user = me
    }

    /// Permanently deletes the account on the server and returns to guest state
    /// (no anonymous re-login — the next value action will prompt sign-in again).
    func deleteAccount() async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            try await AuthAPI.shared.deleteAccount()
            user = nil
            WalletManager.shared.clear()
            PushService.shared.onAuthChanged()
            return true
        } catch {
            errorText = error.localizedDescription
            return false
        }
    }

    /// Silently re-applies active StoreKit entitlements (subscriptions) to the
    /// backend so the current account owns them. Best-effort. Uses the local
    /// entitlement cache (no AppStore.sync(), which would prompt for the Apple
    /// ID password) — that prompt belongs only to the explicit Restore button.
    private func reclaimEntitlements() async {
        await StoreManager.shared.reapplyEntitlements()
    }
}
