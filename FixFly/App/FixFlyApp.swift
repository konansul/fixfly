//
//  FixFlyApp.swift
//  FixFly
//

import SwiftUI
import GoogleSignIn
import KeychainAccess

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
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

    // Re-engagement: arm "come back" reminders when leaving, clear them on return.
    func applicationDidEnterBackground(_ application: UIApplication) {
        NotificationManager.shared.scheduleReengagementReminders()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationManager.shared.cancelReengagementReminders()
    }
}

@main
struct FixFlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppLoadingView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
