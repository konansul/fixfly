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
        // Gate the splash only on auth bootstrap — the lightweight work needed
        // before the UI is usable. Media (preview images + videos) is warmed in
        // the background and must NOT block the splash: on a weak connection
        // downloading every preview took tens of seconds. Cards load their own
        // media lazily (see RemoteCard), so the grid fills in as it arrives.
        await AuthStore.shared.bootstrap()

        // Pull public config (signup bonus amount) so onboarding / guest screens
        // advertise the real number. The UI has a 200 fallback, so this must NOT
        // block the splash — fire and forget.
        Task { await AppConfigStore.shared.refresh() }

        // Warm the media cache in the background; intentionally not awaited.
        Task.detached(priority: .utility) {
            await HomePreloader.shared.preloadHomeContent()
        }

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
