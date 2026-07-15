//
//  ConfigAPI.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import Foundation

enum ConfigAPI {

    // Local dev backend (uncomment for local testing):
    // static let baseURL = "http://192.168.1.78:8000"

    // Production (Azure) — used for App Store / TestFlight builds.
    // New Azure account (migrated 2026-07-16); old account was disabled for non-payment.
    static let baseURL = "https://fixfly-32d3dc.azurewebsites.net"

    static let appStoreID = "6777982481"

    static let appStoreURL = "https://apps.apple.com/app/id\(appStoreID)"

    static let tikTokURL: String? = "https://www.tiktok.com/@fixfly.ai"
}
