//
//  TikTokAnalytics.swift
//  FixFly
//
//  All TikTok Business SDK calls live here so the rest of the app never imports
//  the SDK directly (same rule as AppAnalytics vs Firebase). Everything is
//  wrapped in `#if canImport(TikTokBusinessSDK)`, so the project keeps compiling
//  even before the Swift Package is added in Xcode — the code activates itself
//  the moment the package is present.
//
//  Setup checklist (one-time):
//   1. Xcode → File → Add Package Dependencies →
//      https://github.com/tiktok/tiktok-business-ios-sdk
//   2. Fill in `appId` / `tiktokAppId` below from TikTok Events Manager.
//

import Foundation
import UIKit
import AppTrackingTransparency

#if canImport(TikTokBusinessSDK)
import TikTokBusinessSDK
#endif

enum TikTokAnalytics {

    // MARK: - Credentials (from TikTok Events Manager)

    /// App Store app id — the numeric id in https://apps.apple.com/app/id6777982481
    /// (bundle com.ksultanov.fixfly). Public information, not a secret.
    private static let appId = "6777982481"
    /// TikTok App ID issued in TikTok Events Manager (Events → App Events →
    /// Settings). A distinct value from the App Store id above.
    private static let tiktokAppId = "7656005223063781384"

    // MARK: - Lifecycle

    /// Call once at launch (after FirebaseApp.configure()). The SDK auto-tracks
    /// install + launch by itself once initialized, so we don't forward app_open.
    static func initialize() {
        #if canImport(TikTokBusinessSDK)
        guard appId != "YOUR_APP_ID", tiktokAppId != "YOUR_TIKTOK_APP_ID" else {
            print("[TikTokAnalytics] skipped: appId / tiktokAppId not set")
            return
        }
        let config = TikTokConfig(appId: appId, tiktokAppId: tiktokAppId)
        TikTokBusiness.initializeSdk(config)
        #endif
    }

    /// Show Apple's ATT prompt.
    ///
    /// It must be requested while the app is genuinely foreground-active. At launch
    /// scenePhase flips to `.active` a beat *before* the first window is on screen,
    /// and a request made in that window is silently dropped — the dialog never
    /// appears and the status stays `.notDetermined`. So we wait until the app is
    /// really active (poll briefly if needed) and only then ask. Safe to call
    /// repeatedly: iOS shows the dialog once and later calls return the stored status.
    static func requestTrackingAuthorization() {
        guard #available(iOS 14, *) else { return }
        // Only ever prompt from `.notDetermined`; otherwise it's a no-op anyway.
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _requestWhenActive(attempt: 0)
    }

    private static func _requestWhenActive(attempt: Int) {
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .active {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    // Once authorized the SDK reads IDFA on its own; nothing to do here.
                }
            } else if attempt < 10 {
                // Not on screen yet — try again shortly (up to ~5s).
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    _requestWhenActive(attempt: attempt + 1)
                }
            }
        }
    }

    // MARK: - Events

    /// Forwarded from AppAnalytics.track. Only the funnel events TikTok optimizes
    /// on are sent; everything else (screen views, generate steps, failures) is
    /// dropped to keep the ad signal clean.
    static func track(_ event: AppEvent) {
        #if canImport(TikTokBusinessSDK)
        guard let name = standardEventName(for: event) else { return }
        let tt = TikTokBaseEvent(eventName: name)
        for (key, value) in event.parameters {
            tt.addProperty(withKey: key, value: value)
        }
        TikTokBusiness.trackTTEvent(tt)
        #endif
    }

    /// Maps FixFly events to TikTok Standard Event names. Returns nil for events
    /// that shouldn't go to TikTok. Adjust the strings to match how you want the
    /// campaign to optimize (TikTok's standard set: Registration, ViewContent,
    /// Purchase, Subscribe, …).
    private static func standardEventName(for event: AppEvent) -> String? {
        switch event {
        case .signInWithApple:  return "Registration"
        case .paywallShown:     return "ViewContent"
        case .purchaseSuccess:  return "Purchase"
        default:                return nil
        }
    }
}
