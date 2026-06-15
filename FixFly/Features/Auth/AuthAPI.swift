//
//  AuthAPI.swift
//  FixFly
//

import Foundation

final class AuthAPI {
    static let shared = AuthAPI()
    private init() {}

    func loginWithApple(identityToken: String, fullName: String?) async throws -> TokenResponseDTO {
        var body: [String: Any] = ["identity_token": identityToken]
        if let fullName, !fullName.isEmpty { body["full_name"] = fullName }

        // Apple is the only identity — no current JWT to forward. The backend
        // finds-or-creates the account by the Apple `sub`.
        let dto: TokenResponseDTO = try await ClientAPI.shared.post(
            "/v1/apple",
            jsonBody: body,
            requiresAuth: false
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
