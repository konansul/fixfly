//
//  FixFlyApp.swift
//  FixFly
//

import SwiftUI
import GoogleSignIn
import KeychainAccess

@main
struct FixFlyApp: App {
    var body: some Scene {
        WindowGroup {
            AppLoadingView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
