//
//  HomeAPI.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import Foundation

final class HomeAPI {
    static let shared = HomeAPI()
    private init() {}

    func fetchHome() async throws -> HomeResponse {
        try await ClientAPI.shared.get(
            "/v1/home",
            requiresAuth: false
        )
    }
}
