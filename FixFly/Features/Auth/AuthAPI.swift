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

    func loginWithGoogle(idToken: String) async throws -> TokenResponseDTO {
        let dto: TokenResponseDTO = try await ClientAPI.shared.post(
            "/v1/google",
            jsonBody: ["id_token": idToken],
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
}
