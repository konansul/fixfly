//
//  NetworkSession.swift
//  FixFly
//

import Foundation

/// Shared URLSessions with explicit timeouts. `URLSession.shared` uses a 60s
/// request timeout, so on a weak connection a stalled call hangs for a full
/// minute before failing. These bound that so failures surface quickly (and the
/// UI can retry) instead of leaving the user on an endless spinner.
enum NetworkSession {

    /// Lightweight JSON API calls. Short timeouts — these should be quick, and
    /// on a dead link we'd rather fail fast and show an error than wait.
    static let api: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20   // inactivity gap before giving up
        config.timeoutIntervalForResource = 30  // hard cap for the whole call
        config.urlCache = .shared
        return URLSession(configuration: config)
    }()

    /// Multipart uploads (photo in, image/JSON out). A bigger budget because the
    /// upload itself takes real time on a slow link, but still bounded so it
    /// can't hang forever.
    static let upload: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()

    /// Larger shared on-disk cache so template previews survive app restarts and
    /// aren't re-downloaded on every cold launch. Call once, as early as
    /// possible, before any URLSession is created.
    static func configureSharedCache() {
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,    // 50 MB
            diskCapacity: 500 * 1024 * 1024,     // 500 MB
            diskPath: "fixfly_url_cache"
        )
    }
}
