import Foundation
import SwiftUI
import Combine

@MainActor
final class MyGenerationsViewModel: ObservableObject {
    @Published var items: [GenerationItemDTO] = []
    @Published var isLoading = false
    @Published var errorText: String?

    private let dateFormatterIn: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let dateFormatterInFallback: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private let dateFormatterOut: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    func load(force: Bool = false) async {
        if !force && !items.isEmpty {
            return
        }

        guard AuthStore.shared.isAuthed else {
            errorText = "You are not authenticated."
            items = []
            return
        }

        isLoading = true
        errorText = nil
        
        defer { isLoading = false }

        do {
            let fetchedItems = try await MyGenerationsAPI.shared.fetchMyGenerations(limit: 100)
            self.items = fetchedItems
        } catch {
            errorText = error.localizedDescription
        }
    }

    func formattedDate(_ raw: String?) -> String {
        guard let raw else { return "Unknown date" }

        if let date = dateFormatterIn.date(from: raw) {
            return dateFormatterOut.string(from: date)
        }

        if let date = dateFormatterInFallback.date(from: raw) {
            return dateFormatterOut.string(from: date)
        }

        return raw
    }

    func featureTitle(_ key: String) -> String {
        switch key {
        case "restore_old_photo":
            return "Restore"
        case "enhance_gpt":
            return "Enhance"
        case "anime_avatar":
            return "Anime"
        case "template_to_video":
            return "Video Template"
        case "prompt_to_video":
            return "AI Video"
        case "prompt_to_image":
            return "AI Photo"
        default:
            return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
