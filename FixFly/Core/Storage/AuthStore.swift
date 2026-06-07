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
            
            await WalletManager.shared.refreshBalance()
        } catch {
            errorText = error.localizedDescription
            TokenStore.shared.clear()
            user = nil
            WalletManager.shared.clear()
        }
    }

    func loginWithGoogle(idToken: String) async {
        guard !isLoading else { return }

        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let dto = try await AuthAPI.shared.loginWithGoogle(idToken: idToken)
            self.user = dto.user

            do {
                try await refreshMe()
            } catch {
                // Если нужно, здесь можно добавить обработку ошибки обновления профиля
            }

            await WalletManager.shared.refreshBalance()

            // User changed — re-register the device token under the new account.
            PushService.shared.onAuthChanged()
        } catch {
            errorText = error.localizedDescription
            TokenStore.shared.clear()
            user = nil
            WalletManager.shared.clear()
        }
    }

    func refreshMe() async throws {
        let me = try await AuthAPI.shared.me()
        self.user = me
    }
}
