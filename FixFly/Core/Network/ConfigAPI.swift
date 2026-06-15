//
//  ConfigAPI.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import Foundation

enum ConfigAPI {

    // static let baseURL = "http://192.168.1.78:8000"

    static let baseURL = "https://fixfly-d9hmdbajfbgkfrh2.canadacentral-01.azurewebsites.net"

    /// Numeric App Store Apple ID (App Store Connect → App Information).
    static let appStoreID = "6777982481"

    /// Public App Store page — used by Rate Us / Share App.
    static let appStoreURL = "https://apps.apple.com/app/id\(appStoreID)"
}
