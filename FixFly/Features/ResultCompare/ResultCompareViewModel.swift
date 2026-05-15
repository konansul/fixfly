import SwiftUI
import Photos
import Combine

@MainActor
final class ResultCompareViewModel: ObservableObject {
    
    @Published var toast: String?
    
    func shareItems(for source: MediaSource) -> [Any] {
        switch source {
        case .image(let image):
            return [image]
        case .remote(let raw):
            if let url = absoluteURL(from: raw) {
                return [url]
            }
            return []
        }
    }

    func saveResult(from source: MediaSource) async {
        switch source {
        case .image(let image):
            await saveToPhotos(image)

        case .remote(let raw):
            guard let url = absoluteURL(from: raw) else {
                showToast("Invalid link")
                return
            }

            let isVideo = raw.lowercased().hasSuffix(".mp4") || raw.lowercased().hasSuffix(".mov")

            if isVideo {
                await handleVideoSave(from: url)
            } else {
                await handleImageSave(from: url)
            }
        }
    }

    private func handleImageSave(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                showToast("Error processing image")
                return
            }
            await saveToPhotos(image)
        } catch {
            showToast("Failed to download")
        }
    }

    private func handleVideoSave(from url: URL) async {
        if url.isFileURL {
            await saveVideoToPhotos(url)
            return
        }

        do {
            showToast("Downloading...")
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            let fileManager = FileManager.default
            let newURL = tempURL.deletingPathExtension().appendingPathExtension("mp4")
            
            try? fileManager.removeItem(at: newURL)
            try fileManager.moveItem(at: tempURL, to: newURL)
            
            await saveVideoToPhotos(newURL)
        } catch {
            showToast("Failed to download video")
        }
    }

    private func saveToPhotos(_ image: UIImage) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        if status == .authorized || status == .limited {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            successFeedback()
            return
        }

        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        if newStatus == .authorized || newStatus == .limited {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            successFeedback()
        } else {
            showToast("Photos access denied")
        }
    }

    private func saveVideoToPhotos(_ fileURL: URL) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        if status == .authorized || status == .limited {
            await performVideoSave(fileURL: fileURL)
            return
        }

        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        if newStatus == .authorized || newStatus == .limited {
            await performVideoSave(fileURL: fileURL)
        } else {
            showToast("Photos access denied")
        }
    }

    private func performVideoSave(fileURL: URL) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }
            successFeedback()
        } catch {
            showToast("Failed to save")
        }
    }

    private func successFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        toast = "SUCCESS_ACTION"
    }

    private func showToast(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toast = text
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.toast = nil
            }
        }
    }

    private func absoluteURL(from raw: String) -> URL? {
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") || raw.hasPrefix("file://") {
            return URL(string: raw)
        }
        return URL(string: ConfigAPI.baseURL + raw)
    }
}
