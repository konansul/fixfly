//
//  ResultCompareViewModel.swift
//  FixFly
//

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
                showToast("Bad URL")
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

    // MARK: - Сохранение Картинки
    private func handleImageSave(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                showToast("Bad image data")
                return
            }
            await saveToPhotos(image)
        } catch {
            showToast("Download failed")
        }
    }

    // MARK: - Сохранение Видео
    private func handleVideoSave(from url: URL) async {
        // Если это уже локальный файл (например, сразу после генерации)
        if url.isFileURL {
            await saveVideoToPhotos(url)
            return
        }

        // Если это ссылка из интернета (например, из истории генераций)
        do {
            showToast("Downloading...")
            // Скачиваем во временный файл
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            // Галерея iOS требует, чтобы файл имел правильное расширение (.mp4),
            // поэтому переименовываем скачанный temp-файл.
            let fileManager = FileManager.default
            let newURL = tempURL.deletingPathExtension().appendingPathExtension("mp4")
            
            try? fileManager.removeItem(at: newURL) // Удаляем старый, если был
            try fileManager.moveItem(at: tempURL, to: newURL)
            
            await saveVideoToPhotos(newURL)
            
        } catch {
            showToast("Download failed")
        }
    }

    private func saveToPhotos(_ image: UIImage) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        if status == .authorized || status == .limited {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            showToast("Saved ✅")
            return
        }

        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        if newStatus == .authorized || newStatus == .limited {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            showToast("Saved ✅")
        } else {
            showToast("No Photos permission")
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
            showToast("No Photos permission")
        }
    }

    private func performVideoSave(fileURL: URL) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }
            showToast("Saved ✅")
        } catch {
            showToast("Failed to save video")
        }
    }


    private func showToast(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            toast = text
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
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
