//
//  AnonymousInstallID.swift
//  FixFly
//
//  Created by Kanan Sultanov on 11.03.26.
//

import Foundation
import KeychainAccess

enum AnonymousInstallID {
    private static let keychain = Keychain(service: "fixfly.app")
    private static let key = "install_id"

    static func getOrCreate() -> String {
        if let existing = keychain[key], !existing.isEmpty {
            return existing
        }

        let newID = UUID().uuidString
        keychain[key] = newID
        return newID
    }
}
