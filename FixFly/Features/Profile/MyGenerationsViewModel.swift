import Foundation
import SwiftUI
import Combine

@MainActor
final class MyGenerationsViewModel: ObservableObject {
    @Published var items: [GenerationItemDTO] = []
    @Published var isLoading = false
    @Published var errorText: String?
    
    @Published var refreshId = UUID()

    private let viewedItemsKey = "viewed_generation_ids"

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

    func isNew(_ taskId: String) -> Bool {
        let viewedIds = UserDefaults.standard.stringArray(forKey: viewedItemsKey) ?? []
        return !viewedIds.contains(taskId)
    }

    func markAsViewed(_ taskId: String) {
        var viewedIds = UserDefaults.standard.stringArray(forKey: viewedItemsKey) ?? []
        if !viewedIds.contains(taskId) {
            viewedIds.append(taskId)
            
            if viewedIds.count > 1000 {
                viewedIds = Array(viewedIds.suffix(1000))
            }
            
            UserDefaults.standard.set(viewedIds, forKey: viewedItemsKey)
            objectWillChange.send()
        }
    }

    func load(force: Bool = false) async {
        if !force && !items.isEmpty {
            return
        }

        // Guests aren't an error — the view shows a Sign in with Apple prompt.
        guard AuthStore.shared.isAuthed else {
            errorText = nil
            items = []
            return
        }

        isLoading = true
        errorText = nil
        
        defer { isLoading = false }

        do {
            let fetchedItems = try await MyGenerationsAPI.shared.fetchMyGenerations(limit: 100)
            self.items = fetchedItems
            
            // 2. МЕНЯЕМ ID ТОЛЬКО ПРИ ПРИНУДИТЕЛЬНОМ ОБНОВЛЕНИИ
            if force {
                self.refreshId = UUID()
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    func deleteGeneration(taskId: String) async {
        guard let url = URL(string: ConfigAPI.baseURL + "/v1/my-generations/\(taskId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = TokenStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                withAnimation(.easeInOut) {
                    self.items.removeAll { $0.id == taskId }
                }
            } else {
                self.errorText = "Failed to delete from server"
            }
        } catch {
            self.errorText = error.localizedDescription
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
        case "restore_old_photo": return "Restore"
        case "enhance_gpt": return "Enhance"
        case "anime_avatar": return "Anime"
        case "template_to_video": return "Video Template"
        case "prompt_to_video": return "AI Video"
        case "prompt_to_image": return "AI Photo"
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
