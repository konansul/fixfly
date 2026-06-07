//
//  DeepLinkRouter.swift
//  FixFly
//
//  Routes a tapped push notification into the app. When a "generation done"
//  push is tapped, we stash its taskId here; MainTabView switches to the
//  Profile tab and MyGenerationsView opens that generation's result.
//

import Foundation
import Combine

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    private init() {}

    /// Set when a notification asks us to open a specific generation's result.
    /// Consumed (set back to nil) by MyGenerationsView once handled.
    @Published var pendingGenerationTaskId: String?

    func openGeneration(taskId: String) {
        pendingGenerationTaskId = taskId
    }
}
