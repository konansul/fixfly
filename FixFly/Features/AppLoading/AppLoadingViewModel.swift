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
            try? await AuthStore.shared.bootstrap()
        }()

        async let homePreloadTask: Void = {
            await HomePreloader.shared.preloadHomeContent()
        }()

        _ = await (bootstrapTask, homePreloadTask)

        withAnimation(.easeOut(duration: 0.35)) {
            progress = 1
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        isReady = true
    }
}
