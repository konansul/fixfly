//
//  AuthAPI.swift
//  FixFly
//

import Foundation

final class AuthAPI {
    static let shared = AuthAPI()
    private init() {}

    func loginAnonymous(installID: String) async throws -> AnonymousAuthResponseDTO {
        let dto: AnonymousAuthResponseDTO = try await ClientAPI.shared.post(
            "/v1/auth/anonymous",
            jsonBody: [
                "install_id": installID,
                "platform": "ios",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            ],
            requiresAuth: false
        )

        TokenStore.shared.accessToken = dto.accessToken
        return dto
    }

    func loginWithApple(identityToken: String, fullName: String?) async throws -> TokenResponseDTO {
        var body: [String: Any] = ["identity_token": identityToken]
        if let fullName, !fullName.isEmpty { body["full_name"] = fullName }

        // requiresAuth: true forwards the current anonymous JWT so the backend
        // links Apple to that account (keeps coins/history).
        let dto: TokenResponseDTO = try await ClientAPI.shared.post(
            "/v1/apple",
            jsonBody: body,
            requiresAuth: true
        )
        TokenStore.shared.accessToken = dto.accessToken
        return dto
    }

    func me() async throws -> BackendUserDTO {
        try await ClientAPI.shared.get(
            "/v1/me",
            requiresAuth: true
        )
    }

    func logout() async throws -> String {
        let res: String = try await ClientAPI.shared.request(
            "/v1/logout",
            method: "POST",
            jsonBody: nil,
            requiresAuth: true
        )
        TokenStore.shared.clear()
        return res
    }

    func deleteAccount() async throws {
        let _: OkResponseDTO = try await ClientAPI.shared.request(
            "/v1/account",
            method: "DELETE",
            jsonBody: nil,
            requiresAuth: true
        )
        TokenStore.shared.clear()
    }
}

private struct OkResponseDTO: Decodable {
    let ok: Bool?
}
