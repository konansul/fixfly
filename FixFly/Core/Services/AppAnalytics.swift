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
        FirebaseAnalytics.Analytics.logEvent(event.name, parameters: event.parameters)
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
    case purchaseSuccess(productId: String)
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
        case .purchaseSuccess(let pid):
            return ["product_id": pid]
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
