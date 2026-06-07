//
//  TokenStore.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//
//  The JWT access token is sensitive, so it lives in the Keychain (encrypted),
//  not UserDefaults (plaintext). Uses the same KeychainAccess service as
//  AnonymousInstallID.
//

import Foundation
import KeychainAccess

final class TokenStore {
    static let shared = TokenStore()
    private init() {}

    private let keychain = Keychain(service: "fixfly.app")
    private let key = "fixfly.access_token"

    var accessToken: String? {
        get { keychain[key] }
        set {
            if let value = newValue, !value.isEmpty {
                keychain[key] = value
            } else {
                try? keychain.remove(key)
            }
        }
    }

    func clear() {
        accessToken = nil
    }
}
