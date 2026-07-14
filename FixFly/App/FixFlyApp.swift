//
//  FixFlyApp.swift
//  FixFly
//

import SwiftUI
import KeychainAccess
import FirebaseCore
import FirebaseAnalytics

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Enlarge the shared URL cache before anything makes a request, so
        // template previews persist across launches instead of re-downloading.
        NetworkSession.configureSharedCache()

        // Force transparent nav + tab bars on every iOS version so the app's own
        // background shows through. Without this, iOS 26 defaults the bars to an
        // opaque dark fill (they look black), while older iOS renders them clear —
        // the same build then looks very different per device.
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        FirebaseApp.configure()

        // Don't pollute the production Analytics dataset with events from local
        // test builds — collection stays on only in Release. (Firebase is still
        // configured so Crashlytics/other services keep working.)
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
        #endif

        // TikTok Business SDK — auto-tracks install/launch and receives the
        // funnel events forwarded from AppAnalytics. No-op until the SPM package
        // and the TikTok ids are set (see TikTokAnalytics).
        TikTokAnalytics.initialize()

        AppAnalytics.track(.appOpen)

        // Set the notification delegate early so foreground notifications show
        // and taps are routed.
        NotificationManager.shared.configure()
        return true
    }

    // APNs returned a device token — hand it to PushService to register with the backend.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushService.shared.handleAPNsToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[AppDelegate] remote notification registration failed: \(error)")
    }

    // Re-engagement scheduling moved to FixFlyApp's scenePhase observer —
    // the app-delegate background/active hooks aren't reliable under SwiftUI.
}

@main
struct FixFlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    // Apple's ATT prompt must be shown once, while the app is active.
    @State private var didRequestTracking = false

    var body: some Scene {
        WindowGroup {
            AppLoadingView()
                .preferredColorScheme(.dark)
        }
        // Re-engagement reminders. Driven by scenePhase because in a SwiftUI
        // (scene-based) app the AppDelegate's applicationDidEnterBackground /
        // applicationDidBecomeActive are not reliably called.
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                NotificationManager.shared.scheduleReengagementReminders()
            case .active:
                NotificationManager.shared.cancelReengagementReminders()
                // Ask for tracking permission on the first active state — required
                // before the TikTok SDK can access IDFA for ad attribution.
                if !didRequestTracking {
                    didRequestTracking = true
                    TikTokAnalytics.requestTrackingAuthorization()
                }
            default:
                break
            }
        }
    }
}
