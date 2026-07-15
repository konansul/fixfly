import Foundation
import AVFoundation
import UIKit

final class HomePreloader {
    static let shared = HomePreloader()
    private init() {}

    // Warm only the top of the feed, a few at a time. Preloading every video in
    // every section at once fired dozens of simultaneous downloads on launch,
    // spiking the network radio + CPU (a real source of device heat). Everything
    // below the fold streams and disk-caches on demand as you scroll.
    private static let maxConcurrent = 4
    private static let maxVideos = 10
    private static let maxImages = 24

    private var retainedAssets: [AVURLAsset] = []

    func preloadHomeContent() async {
        do {
            let home = try await HomeAPI.shared.fetchHome()

            let media = collectMediaURLs(from: home)
            let videos = Array(media.videos.prefix(Self.maxVideos))
            let images = Array(media.images.prefix(Self.maxImages))

            async let imageTask: Void = preloadImages(from: images)
            async let videoTask: Void = preloadVideos(from: videos)

            _ = await (imageTask, videoTask)
        } catch {
            print("Home preload failed:", error)
        }
    }

    private func collectMediaURLs(from home: HomeResponse) -> (images: [URL], videos: [URL]) {
        var images: [URL] = []
        var videos: [URL] = []

        for heroItem in home.hero.items {
            if let url = URL(string: heroItem.mediaUrl) {
                switch heroItem.mediaType {
                case "image":
                    images.append(url)
                case "video":
                    videos.append(url)
                    if let poster = heroItem.posterUrl, let posterURL = URL(string: poster) {
                        images.append(posterURL)
                    }
                default:
                    break // Если тип неизвестен, просто пропускаем
                }
            }
        }

        for section in home.sections {
            if let items = section.items {
                append(items: items, images: &images, videos: &videos)
            }

            if let tabs = section.tabs {
                for tab in tabs {
                    append(items: tab.items, images: &images, videos: &videos)
                }
            }
        }

        return (unique(images), unique(videos))
    }

    private func append(items: [RemoteCardItem], images: inout [URL], videos: inout [URL]) {
        for item in items {
            if let url = URL(string: item.mediaUrl) {
                switch item.mediaType {
                case .image:
                    images.append(url)
                case .video:
                    videos.append(url)
                    if let poster = item.posterUrl, let posterURL = URL(string: poster) {
                        images.append(posterURL)
                    }
                }
            }
        }
    }

    /// Run `op` over `items` at most `limit` at a time, so preloading never fires
    /// the whole list of downloads simultaneously.
    private func runBatched<T>(_ items: [T], limit: Int, _ op: @escaping (T) async -> Void) async {
        var index = 0
        while index < items.count {
            let slice = Array(items[index..<min(index + limit, items.count)])
            await withTaskGroup(of: Void.self) { group in
                for item in slice { group.addTask { await op(item) } }
            }
            index += limit
        }
    }

    private func preloadImages(from urls: [URL]) async {
        await runBatched(urls, limit: Self.maxConcurrent) { url in
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                _ = UIImage(data: data)
            } catch {
                print("Image preload failed:", url.absoluteString)
            }
        }
    }

    private func preloadVideos(from urls: [URL]) async {
        retainedAssets.removeAll()

        var index = 0
        while index < urls.count {
            let slice = Array(urls[index..<min(index + Self.maxConcurrent, urls.count)])
            let assets = await withTaskGroup(of: AVURLAsset?.self) { group -> [AVURLAsset] in
                for url in slice {
                    group.addTask {
                        let asset = AVURLAsset(url: url)
                        if (try? await asset.load(.isPlayable)) == true { return asset }
                        return nil
                    }
                }
                var out: [AVURLAsset] = []
                for await asset in group {
                    if let asset { out.append(asset) }
                }
                return out
            }
            retainedAssets.append(contentsOf: assets)
            index += Self.maxConcurrent
        }
    }

    /// Order-preserving dedup, so a later `prefix(...)` keeps the top-of-feed items
    /// (a plain Set would shuffle them and preload a random subset).
    private func unique(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        var out: [URL] = []
        for url in urls where seen.insert(url.absoluteString).inserted {
            out.append(url)
        }
        return out
    }
}
