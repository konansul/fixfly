//
//  MainTabView.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var auth = AuthStore.shared
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }
            
            Tab("Library", systemImage: "photo.on.rectangle") {
                LibraryView()
            }
            
            Tab("Generate", systemImage: "apple.intelligence") {
                GenerateView()
            }
            
            Tab("Profile", systemImage: "person.crop.circle") {
                MyGenerationsView()
            }
            
            Tab(role: .search) {
                LibraryView(activateSearchOnAppear: true)
            }
        }
        .tint(.white)
        .environmentObject(auth)
        .task {
            await auth.bootstrap()
        }
    }
}
