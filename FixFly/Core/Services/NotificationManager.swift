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

    // MARK: - Re-engagement reminders ("we miss you")

    private static let reengageIDs = ["fixfly.reengage.3d", "fixfly.reengage.7d"]

    /// Schedule local "come back" reminders. Call when the app goes to
    /// background; they only ever fire if the user doesn't return (we cancel
    /// them on the next launch/foreground).
    ///
    func scheduleReengagementReminders() {
        cancelReengagementReminders()

        let testingMinutes = false

        let reminders: [(id: String, days: Int, minutes: Int, title: String, body: String)] = [
            ("fixfly.reengage.3d", 3, 5, "We miss you 👋", "Your next AI masterpiece is one tap away — come create something new!"),
            ("fixfly.reengage.7d", 7, 7, "New styles are waiting ✨", "Jump back into FixFly and turn your photo into something epic.")
        ]

        let calendar = Calendar.current
        for reminder in reminders {
            let trigger: UNNotificationTrigger
            if testingMinutes {
                trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(reminder.minutes * 60), repeats: false
                )
            } else {
                guard let fireDate = calendar.date(byAdding: .day, value: reminder.days, to: Date()) else { continue }
                var comps = calendar.dateComponents([.year, .month, .day], from: fireDate)
                comps.hour = 18
                comps.minute = 0
                trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            }

            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
            center.add(request)
        }
    }

    /// Cancel pending re-engagement reminders — call when the user returns.
    func cancelReengagementReminders() {
        center.removePendingNotificationRequests(withIdentifiers: Self.reengageIDs)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Show notifications even while the app is in the foreground (banner +
    /// sound + Notification Center), so coin/generation/re-engagement alerts are
    /// visible without backgrounding the app.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
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
