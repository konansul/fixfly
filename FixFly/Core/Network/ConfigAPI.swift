//
//  ConfigAPI.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import Foundation

enum ConfigAPI {

    // MARK: - Backend URL (remote-configurable)

    // The ONE hardcoded anchor: a stable file on GitHub Pages that never moves.
    // The real backend URL lives inside it, so the backend can be moved WITHOUT
    // an App Store resubmit — you change config.json, not the app.
    private static let remoteConfigURL = "https://konansul.github.io/fixfly-legal/config.json"

    // Used until remote config is fetched (fresh installs, offline). Keep it
    // pointed at the current backend at each release.
    // Local dev: temporarily set this to e.g. "http://192.168.1.78:8000".
    private static let fallbackBaseURL = "https://fixfly-32d3dc.azurewebsites.net"

    private static let cachedBaseURLKey = "fixfly.api.baseURL"

    // Best-known backend URL: the cached remote value if we have one, else the
    // fallback. Read fresh on every request (callers build URLs inline), so a
    // refresh that lands mid-session is picked up on the next call.
    static var baseURL: String {
        UserDefaults.standard.string(forKey: cachedBaseURLKey) ?? fallbackBaseURL
    }

    // Fetch the latest backend URL from remote config and cache it. Best-effort:
    // on any failure we silently keep the cached/fallback value. Call once, early
    // at launch. Non-blocking — this session uses the cached/fallback value and a
    // freshly-changed URL takes effect on the next launch (or this one, if the
    // fetch beats the first request).
    static func refreshBaseURL() async {
        guard let url = URL(string: remoteConfigURL) else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 4
        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            (response as? HTTPURLResponse)?.statusCode == 200,
            let config = try? JSONDecoder().decode(RemoteConfig.self, from: data)
        else { return }
        let value = config.apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        // Only accept a real https URL, and drop a trailing slash so callers can
        // safely do `baseURL + "/v1/..."`.
        guard value.hasPrefix("https://") else { return }
        let normalized = value.hasSuffix("/") ? String(value.dropLast()) : value
        UserDefaults.standard.set(normalized, forKey: cachedBaseURLKey)
    }

    private struct RemoteConfig: Decodable {
        let apiBaseURL: String
        enum CodingKeys: String, CodingKey { case apiBaseURL = "api_base_url" }
    }

    // MARK: - Static links

    static let appStoreID = "6777982481"

    static let appStoreURL = "https://apps.apple.com/app/id\(appStoreID)"

    static let tikTokURL: String? = "https://www.tiktok.com/@fixflyapp"
}
