//
//  NotificationManager.swift
//  FixFly
//
//  Central place for everything notifications. Step 2: permission + a local
//  test notification so we can confirm the whole pipeline works on device.
//  Remote push (APNs) will plug into this same class later.
//

import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    enum Status {
        case notDetermined
        case authorized
        case denied
    }

    @Published private(set) var status: Status = .notDetermined

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    /// Call once at launch. Sets us as the delegate so notifications are shown
    /// while the app is in the foreground and taps are routed here.
    func configure() {
        center.delegate = self
        Task {
            await refreshStatus()
            // If already authorized, register for remote push so we get a fresh
            // APNs token each launch (tokens can change).
            if status == .authorized {
                print("[NotificationManager] calling registerForRemoteNotifications()")
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    /// Ask the user for permission. Returns whether it was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            if granted {
                // Kick off remote push registration → AppDelegate receives the token.
                print("[NotificationManager] calling registerForRemoteNotifications()")
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            await refreshStatus()
            return false
        }
    }

    /// Fire a local notification a few seconds from now — purely to verify the
    /// permission + delivery pipeline. Background the app to see the banner,
    /// or stay in the app (it still shows, thanks to the delegate below).
    func scheduleTestNotification(after seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "FixFly"
        content.body = "Test notification — everything works 🎉"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, seconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "fixfly.test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            status = .authorized
        case .notDetermined:
            status = .notDetermined
        default:
            status = .denied
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Don't show a banner while the app is in the foreground — the in-app UI
    /// already reflects generation progress/results, so a banner would just
    /// duplicate it. (Return [.banner, .sound] here if you ever want it shown.)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([])
    }

    /// Called when the user taps a notification. For a finished generation we
    /// deep-link to its result via DeepLinkRouter.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let taskId = userInfo["taskId"] as? String
        let type = userInfo["type"] as? String

        Task { @MainActor in
            if let taskId, type == "generation_done" {
                DeepLinkRouter.shared.openGeneration(taskId: taskId)
            }
        }
        completionHandler()
    }
}
