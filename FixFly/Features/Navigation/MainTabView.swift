//
//  MainTabView.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import SwiftUI

enum AppTab: Hashable {
    case home, library, generate, profile
}

struct MainTabView: View {
    @StateObject private var auth = AuthStore.shared
    @ObservedObject private var router = DeepLinkRouter.shared
    @State private var selection: AppTab = .home

    // "apple.intelligence" only exists from iOS 18.1 (SF Symbols 6.1).
    private var generateIcon: String {
        if #available(iOS 18.1, *) {
            return "apple.intelligence"
        } else {
            return "sparkles"
        }
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeView()
            }

            Tab("Library", systemImage: "photo.on.rectangle", value: AppTab.library) {
                LibraryView()
            }

            Tab("Generate", systemImage: generateIcon, value: AppTab.generate) {
                GenerateView()
            }

            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                MyGenerationsView()
            }
        }
        .tint(.white)
        .environmentObject(auth)
        .task {
            await auth.bootstrap()
        }
        .onChange(of: router.pendingGenerationTaskId) { _, newValue in
            // A tapped "generation done" push wants to open the result — that
            // lives in the Profile tab, so switch to it.
            if newValue != nil {
                selection = .profile
            }
        }
    }
}
