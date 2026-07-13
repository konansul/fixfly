//
//  PhotoshootAPI.swift
//  FixFly
//

import UIKit

final class PhotoshootAPI {
    static let shared = PhotoshootAPI()
    private init() {}

    /// The catalog is public (like Home) so guests can browse before signing in.
    func fetchTemplates() async throws -> PhotoshootCatalogResponse {
        try await ClientAPI.shared.get("/v1/photoshoot-templates", requiresAuth: false)
    }

    /// Starts a shoot. Returns the task id to poll on the processing screen.
    func start(templateId: String, selfie: UIImage) async throws -> String {
        try await MultipartAPI.shared.startBackgroundGeneration(
            endpointPath: "/v1/generate-photoshoot",
            images: [selfie],
            extraFields: ["template": templateId]
        )
    }

    /// After the job is done, fetch the full 5-photo set from the status endpoint
    /// (output_url alone is just the anchor). Falls back to the anchor on failure.
    func fetchOutputs(taskId: String) async -> [String] {
        do {
            let status: TaskStatusResponse = try await ClientAPI.shared.get(
                "/v1/generations/status/\(taskId)",
                requiresAuth: true
            )
            if let outputs = status.outputs, !outputs.isEmpty { return outputs }
            if let single = status.output_url { return [single] }
        } catch {
        }
        return []
    }
}
