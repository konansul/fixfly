//
//  FixFlyApp.swift
//  FixFly
//

import SwiftUI
import KeychainAccess
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Enlarge the shared URL cache before anything makes a request, so
        // template previews persist across launches instead of re-downloading.
        NetworkSession.configureSharedCache()

        FirebaseApp.configure()
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
            default:
                break
            }
        }
    }
}
