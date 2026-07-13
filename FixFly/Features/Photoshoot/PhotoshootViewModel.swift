//
//  PhotoshootViewModel.swift
//  FixFly
//

import SwiftUI
import Combine

@MainActor
final class PhotoshootViewModel: ObservableObject {
    @Published var templates: [PhotoshootTemplateDTO] = []
    @Published var cost: Int = 600
    @Published var isLoading = false
    @Published var errorText: String?

    func load(force: Bool = false) async {
        if !force && !templates.isEmpty { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }
        do {
            let resp = try await PhotoshootAPI.shared.fetchTemplates()
            self.templates = resp.templates
            self.cost = resp.cost
        } catch {
            self.errorText = error.localizedDescription
        }
    }
}
