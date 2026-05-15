//
//  PhotoProcessingViewModel.swift
//  FixFly
//
//  Created by Kanan Sultanov on 27.03.26.
//

import SwiftUI
import Combine
import UserNotifications

enum PhotoNotificationStatus {
    case notDetermined
    case authorized
    case denied
}

struct TaskStatusResponse: Decodable {
    let status: String
    let progress: Double?
    let output_url: String?
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
    
    private let pollInterval = 3.0
    private var startTime: Date?

    init(taskId: String) {
        self.taskId = taskId
        self.startTime = Date()
        checkNotificationStatus()
    }
    
    func startPollingStatus() async {
        guard !taskId.isEmpty else { return }
        
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
                        progressAmount = 1.0
                        remainingTimeEstimate = "Done!"
                        isProcessingComplete = true
                        break
                    } else if statusResponse.status == "failed" {
                        errorText = statusResponse.error_text
                        remainingTimeEstimate = "Failed"
                        hasError = true
                        break
                    } else {
                        if let exactProgress = statusResponse.progress {
                            progressAmount = exactProgress
                        } else {
                            let elapsedTime = Date().timeIntervalSince(startTime ?? Date())
                            progressAmount = min(0.95, elapsedTime / 180.0)
                        }
                        
                        if statusResponse.status == "queued" {
                            remainingTimeEstimate = "In queue..."
                        } else {
                            remainingTimeEstimate = "Processing..."
                        }
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
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.notificationStatus = .authorized
                } else {
                    self.notificationStatus = .denied
                }
            }
        }
    }
}
