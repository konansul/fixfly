//
//  AppSession.swift
//  FixFly
//

import Foundation

enum AppSession {
    /// Random seed generated once per app launch. As a `static let` it is
    /// initialized exactly once per process, so it stays constant while the app
    /// is running and gets a fresh value on the next cold launch.
    ///
    /// Sent to /v1/home and /v1/library as `?seed=` so their random rows (Random
    /// Mix, Library shuffle) stay stable across tab switches and only re-roll
    /// when the app is relaunched.
    static let seed = UUID().uuidString
}
