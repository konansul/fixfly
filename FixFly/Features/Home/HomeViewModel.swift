//
//  HomeViewModel.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var home: HomeResponse?
    @Published var isLoading = false
    @Published var errorText: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let decoded = try await HomeAPI.shared.fetchHome()
            self.home = decoded
        } catch {
            self.errorText = (error as NSError).localizedDescription
        }
    }
}
