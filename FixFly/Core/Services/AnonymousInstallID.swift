//
//  AnonymousInstallID.swift
//  FixFly
//
//  Created by Kanan Sultanov on 11.03.26.
//

import Foundation
import KeychainAccess

/// Stable per-install id used to dedupe anonymous accounts on the backend.
///
/// Keychain is preferred (it survives app reinstalls), but the KeychainAccess
/// subscript setter silently swallows write errors — on some devices the write
/// fails, so the next launch reads nothing and a *new* id (and a new anonymous
/// user) is created every launch. To prevent that, the id is mirrored in
/// UserDefaults, which always persists across launches within an install. So
/// even if the Keychain write fails, the id stays stable.
enum AnonymousInstallID {
    private static let keychain = Keychain(service: "fixfly.app")
    private static let key = "install_id"
    private static let defaultsKey = "fixfly.install_id"

    static func getOrCreate() -> String {
        // 1) Keychain first (survives reinstall). Mirror into UserDefaults so a
        //    later Keychain failure can't lose it.
        if let existing = keychain[key], !existing.isEmpty {
            UserDefaults.standard.set(existing, forKey: defaultsKey)
            return existing
        }

        // 2) Fall back to UserDefaults (survives Keychain write failures across
        //    launches — the cause of duplicate anonymous users). Repair the
        //    Keychain copy best-effort.
        if let stored = UserDefaults.standard.string(forKey: defaultsKey), !stored.isEmpty {
            try? keychain.set(stored, key: key)
            return stored
        }

        // 3) First launch on this install: create and persist to BOTH stores.
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: defaultsKey)
        try? keychain.set(newID, key: key)
        return newID
    }
}
