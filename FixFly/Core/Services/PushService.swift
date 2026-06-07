//
//  PushService.swift
//  FixFly
//
//  Step 4 (iOS side): takes the APNs device token from the AppDelegate and
//  registers it with the backend (POST /v1/devices), so the server can push
//  "your video is ready" notifications to this device.
//
//  Self-healing: the token may arrive before we have a JWT (auth bootstrap is
//  async). We cache it and (re)try syncing whenever auth becomes available.
//

import Foundation
import UIKit

final class PushService {
    static let shared = PushService()
    private init() {}

    private let tokenKey = "fixfly.apns_token"
    private let syncedTokenKey = "fixfly.apns_token_synced"

    // Tells the backend which APNs host to use. Debug builds get the sandbox
    // aps-environment entitlement; TestFlight/App Store get production.
    #if DEBUG
    private let environment = "sandbox"
    #else
    private let environment = "production"
    #endif

    /// Called from the AppDelegate with the raw APNs token.
    func handleAPNsToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("[PushService] received APNs token: \(hex.prefix(12))…")
        UserDefaults.standard.set(hex, forKey: tokenKey)
        // A new token invalidates any previous successful sync.
        if UserDefaults.standard.string(forKey: syncedTokenKey) != hex {
            UserDefaults.standard.removeObject(forKey: syncedTokenKey)
        }
        Task { await syncIfPossible() }
    }

    /// Call after auth changes (login / relaunch) so a token captured earlier,
    /// or a token that now belongs to a different user, gets (re)registered.
    func onAuthChanged() {
        UserDefaults.standard.removeObject(forKey: syncedTokenKey)
        Task { await syncIfPossible() }
    }

    /// Sends the stored token to the backend if we have one, are authed, and it
    /// hasn't already been synced. Safe to call repeatedly.
    func syncIfPossible() async {
        guard
            let hex = UserDefaults.standard.string(forKey: tokenKey),
            !hex.isEmpty
        else { return }

        guard TokenStore.shared.accessToken?.isEmpty == false else {
            print("[PushService] have APNs token but no JWT yet — will retry after auth")
            return
        }

        if UserDefaults.standard.string(forKey: syncedTokenKey) == hex { return } // already sent

        let body: [String: Any] = [
            "token": hex,
            "platform": "ios",
            "install_id": AnonymousInstallID.getOrCreate(),
            "environment": environment
        ]

        do {
            let _: RegisterDeviceResponse = try await ClientAPI.shared.post(
                "/v1/devices",
                jsonBody: body,
                requiresAuth: true
            )
            UserDefaults.standard.set(hex, forKey: syncedTokenKey)
            print("[PushService] device token registered with backend")
        } catch {
            // Backend not ready / no auth / network — keep token pending, retry later.
            print("[PushService] token sync failed: \(error)")
        }
    }
}

private struct RegisterDeviceResponse: Decodable {
    let ok: Bool?
}
