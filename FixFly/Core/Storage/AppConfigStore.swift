//
//  AppConfigStore.swift
//  FixFly
//
//  Public, unauthenticated app config fetched from the backend at launch.
//  Currently just the signup bonus amount, so the pre–sign-in UI ("get N free
//  coins") shows the REAL value and stays in sync with the backend's
//  SIGNUP_BONUS_COINS without shipping a new build. Until/if the fetch returns,
//  a sensible default is used so the copy is never blank.
//
//  NB: distinct from `ConfigAPI` (which only holds the base URL) — this is live
//  remote config.
//

import Foundation
import Combine

@MainActor
final class AppConfigStore: ObservableObject {

    static let shared = AppConfigStore()

    /// Free coins granted on the first Sign in with Apple. Default matches the
    /// backend's current SIGNUP_BONUS_COINS; refreshed from /v1/config on launch.
    @Published private(set) var signupBonusCoins: Int = 200

    private init() {}

    /// Best-effort refresh. Never throws — on failure the fallback stays, so the
    /// UI is safe to read `signupBonusCoins` at any time.
    func refresh() async {
        do {
            let dto: AppConfigDTO = try await ClientAPI.shared.get(
                "/v1/config",
                requiresAuth: false
            )
            // Take the server value verbatim, INCLUDING 0: when the bonus is
            // disabled (SIGNUP_BONUS_COINS=0) every promo is gated on `> 0`, so
            // this hides them. Ignoring 0 here would keep the 200 fallback and
            // advertise a bonus the backend no longer grants.
            signupBonusCoins = max(0, dto.signupBonusCoins)
        } catch {
            // Network error only — keep the fallback so the copy is never blank.
        }
    }
}

private struct AppConfigDTO: Decodable {
    let signupBonusCoins: Int

    enum CodingKeys: String, CodingKey {
        case signupBonusCoins = "signup_bonus_coins"
    }
}
