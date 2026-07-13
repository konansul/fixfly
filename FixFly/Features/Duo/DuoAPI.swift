//
//  DuoAPI.swift
//  FixFly
//

import UIKit

final class DuoAPI {
    static let shared = DuoAPI()
    private init() {}

    /// The catalog is public (like Home) so guests can browse before signing in.
    func fetchTemplates() async throws -> DuoCatalogResponse {
        try await ClientAPI.shared.get("/v1/duo-templates", requiresAuth: false)
    }

    /// Starts a duo. `photos` map in order to input_0, input_1 (1 or 2 depending
    /// on the template). Returns the task id to poll on the processing screen.
    func start(templateId: String, photos: [UIImage]) async throws -> String {
        try await MultipartAPI.shared.startBackgroundGeneration(
            endpointPath: "/v1/generate-duo",
            images: photos,
            extraFields: ["template": templateId]
        )
    }
}
