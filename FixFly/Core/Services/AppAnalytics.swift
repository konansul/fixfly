//
//  AppAnalytics.swift
//  FixFly
//
//  Central analytics. Call sites use `AppAnalytics.track(.paywallShown(...))`
//  and never import Firebase directly, so the backend SDK stays swappable.
//

import Foundation
import FirebaseAnalytics

enum AppAnalytics {
    static func track(_ event: AppEvent) {
        // Screen views go through Firebase's reserved event so they land in the
        // built-in "Screens" report.
        if case .screen(let name) = event {
            FirebaseAnalytics.Analytics.logEvent(
                AnalyticsEventScreenView,
                parameters: [AnalyticsParameterScreenName: name]
            )
            return
        }

        // Revenue only reaches Firebase's reports through the reserved `purchase`
        // event. Logged as a custom `purchase_success` it showed up as an event
        // with zero money attached, so the console reported no revenue at all.
        if case .purchaseSuccess = event {
            FirebaseAnalytics.Analytics.logEvent(
                AnalyticsEventPurchase,
                parameters: event.parameters
            )
            TikTokAnalytics.track(event)
            return
        }

        FirebaseAnalytics.Analytics.logEvent(event.name, parameters: event.parameters)

        // Mirror the funnel events TikTok optimizes ads on. TikTokAnalytics
        // decides which ones matter and is a no-op until the SDK is added.
        TikTokAnalytics.track(event)
    }
}

/// Funnel + navigation events. Keep it tight — these answer "what screens do
/// people open, what do they tap, where do they drop off, what converts".
enum AppEvent {
    case appOpen
    case screen(name: String)              // a screen/tab opened
    case featureSelected(kind: String)     // tapped AI Photo / AI Video card
    case templateOpened(template: String?) // opened the full-screen template feed
    case paywallShown(source: String)
    /// `value` and `currency` are what make this a revenue event. Without them
    /// Firebase reports zero revenue and TikTok can only optimise on the *count*
    /// of purchases, never on their value.
    case purchaseSuccess(productId: String, value: Double, currency: String, transactionId: String?)
    case purchaseFailed(productId: String, reason: String)
    case generateStarted(kind: String, template: String?)
    case generateCompleted(kind: String)
    case generateFailed(kind: String, reason: String)
    case signInWithApple

    var name: String {
        switch self {
        case .appOpen:           return "app_open"
        case .screen:            return "screen_view"
        case .featureSelected:   return "feature_selected"
        case .templateOpened:    return "template_opened"
        case .paywallShown:      return "paywall_shown"
        case .purchaseSuccess:   return "purchase_success"
        case .purchaseFailed:    return "purchase_failed"
        case .generateStarted:   return "generate_started"
        case .generateCompleted: return "generate_completed"
        case .generateFailed:    return "generate_failed"
        case .signInWithApple:   return "sign_in_with_apple"
        }
    }

    var parameters: [String: Any] {
        switch self {
        case .appOpen, .signInWithApple:
            return [:]
        case .screen(let name):
            return ["screen_name": name]
        case .featureSelected(let kind):
            return ["kind": kind]
        case .templateOpened(let template):
            var p: [String: Any] = [:]
            if let template, !template.isEmpty { p["template"] = template }
            return p
        case .paywallShown(let source):
            return ["source": source]
        case .purchaseSuccess(let pid, let value, let currency, let txId):
            // The keys are Firebase's reserved names — and TikTok reads the same
            // two ("value", "currency") off a Purchase event, so one dictionary
            // serves both.
            var p: [String: Any] = [
                "product_id": pid,
                AnalyticsParameterValue: value,
                AnalyticsParameterCurrency: currency,
            ]
            if let txId { p[AnalyticsParameterTransactionID] = txId }
            return p
        case .purchaseFailed(let pid, let reason):
            return ["product_id": pid, "reason": String(reason.prefix(100))]
        case .generateStarted(let kind, let template):
            var p: [String: Any] = ["kind": kind]
            if let template, !template.isEmpty { p["template"] = template }
            return p
        case .generateCompleted(let kind):
            return ["kind": kind]
        case .generateFailed(let kind, let reason):
            return ["kind": kind, "reason": String(reason.prefix(100))]
        }
    }
}
