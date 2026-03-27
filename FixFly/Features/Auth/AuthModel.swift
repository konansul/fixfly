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

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case user
    }
}

struct AnonymousAuthResponseDTO: Decodable {
    let accessToken: String
    let user: BackendUserDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}
