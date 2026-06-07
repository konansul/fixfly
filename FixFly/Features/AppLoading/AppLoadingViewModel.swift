//
//  AppLoadingViewModel.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//

import SwiftUI
import Combine

@MainActor
final class AppLoadingViewModel: ObservableObject {
    
    @Published var isReady = false
    @Published var progress: CGFloat = 0.0
    
    func startFakeProgress() {
        Task {
            while progress < 0.9 {
                try? await Task.sleep(nanoseconds: 60_000_000)
                progress += 0.01
            }
        }
    }
    
    func preload() async {
        async let bootstrapTask: Void = {
            await AuthStore.shared.bootstrap()
        }()

        async let homePreloadTask: Void = {
            await HomePreloader.shared.preloadHomeContent()
        }()

        _ = await (bootstrapTask, homePreloadTask)

        // JWT is ready now — register any cached APNs token with the backend.
        await PushService.shared.syncIfPossible()

        withAnimation(.easeOut(duration: 0.35)) {
            progress = 1
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        withAnimation(.easeInOut(duration: 0.5)) {
            isReady = true
        }
    }
}
