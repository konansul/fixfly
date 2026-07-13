//
//  PhotoProcessingViewModel.swift
//  FixFly
//
//  Created by Kanan Sultanov on 27.03.26.
//

import SwiftUI
import Combine
import UserNotifications
import UIKit

enum PhotoNotificationStatus {
    case notDetermined
    case authorized
    case denied
}

struct TaskStatusResponse: Decodable {
    let status: String
    let progress: Double?
    let output_url: String?
    /// A photoshoot's full 5-photo set (nil for single-output features).
    let outputs: [String]?
    let error_text: String?
}

@MainActor
class PhotoProcessingViewModel: ObservableObject {
    let taskId: String
    
    @Published var progressAmount: Double = 0.0
    @Published var remainingTimeEstimate: String = "Connecting..."
    @Published var notificationStatus: PhotoNotificationStatus = .notDetermined
    @Published var isProcessingComplete = false
    @Published var hasError = false
    @Published var outputUrl: String?
    @Published var errorText: String?
    
    private var startTime: Date?

    /// Generations almost never finish before ~10 s, so the first status
    /// check waits that long; after that we poll every 5 s. For a typical
    /// 30 s generation that's ~5 requests total. The progress ring animates
    /// on its own timer (see startPollingStatus), so the rare polls don't
    /// make the UI feel less alive.
    private let initialPollDelay: TimeInterval = 10
    private let pollInterval: TimeInterval = 5
    /// The ring fills up over this many seconds (capped at 95% until done).
    private let expectedDuration: TimeInterval = 40

    init(taskId: String) {
        self.taskId = taskId
        self.startTime = Date()
        checkNotificationStatus()
    }
    
    func startPollingStatus() async {
        guard !taskId.isEmpty else { return }

        // Smooth, purely local progress animation — no network involved.
        let progressTask = Task {
            remainingTimeEstimate = "Processing..."
            while !isProcessingComplete && !hasError && !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime ?? Date())
                progressAmount = min(0.95, elapsed / expectedDuration)
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        defer { progressTask.cancel() }

        // No generation finishes that fast — don't even ask the backend yet.
        try? await Task.sleep(nanoseconds: UInt64(initialPollDelay * 1_000_000_000))

        while !isProcessingComplete && !hasError {
            do {
                guard let url = URL(string: ConfigAPI.baseURL + "/v1/generations/status/\(taskId)") else { return }
                var request = URLRequest(url: url)
                if let token = TokenStore.shared.accessToken {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let statusResponse = try JSONDecoder().decode(TaskStatusResponse.self, from: data)

                    if statusResponse.status == "done" {
                        outputUrl = statusResponse.output_url
                        let kind = (statusResponse.output_url?.lowercased().hasSuffix(".mp4") == true) ? "video" : "photo"
                        AppAnalytics.track(.generateCompleted(kind: kind))
                        progressAmount = 1.0
                        remainingTimeEstimate = "Done!"
                        isProcessingComplete = true
                        break
                    } else if statusResponse.status == "failed" {
                        errorText = statusResponse.error_text
                        AppAnalytics.track(.generateFailed(kind: "unknown", reason: statusResponse.error_text ?? "unknown"))
                        remainingTimeEstimate = "Failed"
                        hasError = true
                        break
                    } else if statusResponse.status == "queued" {
                        remainingTimeEstimate = "In queue..."
                    } else {
                        remainingTimeEstimate = "Processing..."
                    }
                }
            } catch {
            }

            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
    }

    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.notificationStatus = .notDetermined
                case .authorized, .provisional:
                    self.notificationStatus = .authorized
                default:
                    self.notificationStatus = .denied
                }
            }
        }
    }
    
    func requestNotificationPermission() {
        if notificationStatus == .authorized { return }

        // Route through NotificationManager so a grant also registers for remote
        // push (APNs token → backend). Requesting directly here only enabled
        // local notifications and left the backend with no device to push to.
        Task { @MainActor in
            let granted = await NotificationManager.shared.requestAuthorization()
            self.notificationStatus = granted ? .authorized : .denied
        }
    }

    /// Drives the "Notify Me When Ready" button. If the user hasn't decided yet,
    /// ask. If they already denied (e.g. on the launch prompt), iOS won't show
    /// the system dialog again — so send them to Settings to enable it.
    func enableNotifications() {
        switch notificationStatus {
        case .authorized:
            return
        case .notDetermined:
            requestNotificationPermission()
        case .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
}
