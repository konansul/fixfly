//
//  AuthModel.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import Foundation

struct BackendUserDTO: Decodable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
    }
}

struct TokenResponseDTO: Decodable {
    let accessToken: String
    let tokenType: String
    let user: BackendUserDTO
    /// One-time welcome coins granted on this sign-in (0 for returning users or
    /// when the bonus is disabled on the backend).
    let signupBonusGranted: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
        case signupBonusGranted = "signup_bonus_granted"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try c.decode(String.self, forKey: .accessToken)
        tokenType = try c.decodeIfPresent(String.self, forKey: .tokenType) ?? "bearer"
        user = try c.decode(BackendUserDTO.self, forKey: .user)
        signupBonusGranted = try c.decodeIfPresent(Int.self, forKey: .signupBonusGranted) ?? 0
    }
}
