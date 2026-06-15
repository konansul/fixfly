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

    private init() {}

    var isAuthed: Bool {
        TokenStore.shared.accessToken != nil
    }

    func bootstrap() async {
        errorText = nil

        if isAuthed {
            do {
                try await refreshMe()
                await WalletManager.shared.refreshBalance()
                return
            } catch {
                // токен невалидный
                TokenStore.shared.clear()
                user = nil
                WalletManager.shared.clear()
            }
        }

        await loginAnonymous()
    }

    func loginAnonymous() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let installID = AnonymousInstallID.getOrCreate()
            let dto = try await AuthAPI.shared.loginAnonymous(installID: installID)
            self.user = dto.user

            if dto.signupBonusGranted > 0 {
                self.pendingSignupBonus = dto.signupBonusGranted
            }

            await WalletManager.shared.refreshBalance()
        } catch {
            errorText = error.localizedDescription
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

            try? await refreshMe()
            await WalletManager.shared.refreshBalance()

            // User may have switched (returning user on a new device) — re-register
            // the device token under the resolved account.
            PushService.shared.onAuthChanged()
        } catch {
            // Keep the existing anonymous session on failure — don't sign out.
            errorText = error.localizedDescription
        }
    }

    func refreshMe() async throws {
        let me = try await AuthAPI.shared.me()
        self.user = me
    }

    /// Permanently deletes the account on the server, then starts a fresh
    /// anonymous session so the app stays usable.
    func deleteAccount() async -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            try await AuthAPI.shared.deleteAccount()
            user = nil
            WalletManager.shared.clear()
            await loginAnonymous()           // new empty anonymous account
            PushService.shared.onAuthChanged()
            return true
        } catch {
            errorText = error.localizedDescription
            return false
        }
    }
}
