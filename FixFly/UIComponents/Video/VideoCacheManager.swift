//
//  VideoCacheManager.swift
//  FixFly
//
//  Created by Kanan Sultanov on 27.03.26.
//

import Foundation
import CryptoKit

class VideoCacheManager {
    static let shared = VideoCacheManager()
    private let cacheDirectory: URL

    // Словарь, чтобы не скачивать одно и то же видео дважды одновременно
    private var downloadTasks: [URL: Task<URL, Error>] = [:]
    private let queue = DispatchQueue(label: "com.fixfly.videocache")

    private init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("VideoCache")
        
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func getCachedURL(for url: URL) async -> URL {
        // Key on a hash of the FULL url: generation outputs are all named
        // "output.mp4", so lastPathComponent alone would collide.
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hash = digest.map { String(format: "%02x", $0) }.joined().prefix(32)
        let fileName = "\(hash).\(url.pathExtension.isEmpty ? "mp4" : url.pathExtension)"
        let localURL = cacheDirectory.appendingPathComponent(fileName)

        // 1. Если файл уже есть на диске, моментально отдаем его
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }

        // 2. Проверяем, не скачивается ли уже это видео другим элементом интерфейса
        let existingTask = queue.sync { downloadTasks[url] }
        if let task = existingTask {
            return (try? await task.value) ?? url
        }

        // 3. Создаем новую задачу на скачивание (напрямую на диск)
        let task = Task<URL, Error> {
            do {
                // Используем download(from:) вместо data(from:) - это спасает память и процессор!
                let (tempURL, _) = try await URLSession.shared.download(from: url)
                
                if FileManager.default.fileExists(atPath: localURL.path) {
                    try? FileManager.default.removeItem(at: localURL)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                return localURL
            } catch {
                throw error
            }
        }

        queue.sync { downloadTasks[url] = task }

        do {
            let finalURL = try await task.value
            queue.sync { downloadTasks[url] = nil }
            return finalURL
        } catch {
            queue.sync { downloadTasks[url] = nil }
            return url
        }
    }
}
