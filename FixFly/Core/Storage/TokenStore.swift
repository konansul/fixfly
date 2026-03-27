//
//  TokenStore.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import Foundation

final class TokenStore {
    static let shared = TokenStore()
    private init() {}

    private let key = "fixfly.access_token"

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set {
            if let v = newValue {
                UserDefaults.standard.set(v, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    func clear() {
        accessToken = nil
    }
}
