//
//  MyGenerationsAPI.swift
//  FixFly
//
//  Created by Kanan Sultanov on 11.03.26.
//


import Foundation

final class MyGenerationsAPI {
    static let shared = MyGenerationsAPI()
    private init() {}

    func fetchMyGenerations(limit: Int = 50) async throws -> [GenerationItemDTO] {
        let response: MyGenerationsResponse = try await ClientAPI.shared.get(
            "/v1/my-generations?limit=\(limit)",
            requiresAuth: true
        )
        return response.items
    }
}
