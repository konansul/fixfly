//
//  ClientAPI.swift
//  FixFly
//

import Foundation

final class ClientAPI {
    static let shared = ClientAPI()
    private init() {}

    func get<T: Decodable>(
        _ path: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            path,
            method: "GET",
            jsonBody: nil,
            requiresAuth: requiresAuth
        )
    }

    func post<T: Decodable>(
        _ path: String,
        jsonBody: [String: Any],
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            path,
            method: "POST",
            jsonBody: jsonBody,
            requiresAuth: requiresAuth
        )
    }

    func request<T: Decodable>(
        _ path: String,
        method: String,
        jsonBody: [String: Any]?,
        requiresAuth: Bool = true
    ) async throws -> T {

        guard let url = URL(string: ConfigAPI.baseURL + path) else {
            throw ErrorAPI.badURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            guard let token = TokenStore.shared.accessToken, !token.isEmpty else {
                throw ErrorAPI.http(401, "Missing access token")
            }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let jsonBody {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        }

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw ErrorAPI.badResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "Server error"
            throw ErrorAPI.http(http.statusCode, text)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ErrorAPI.decoding(error)
        }
    }
}
