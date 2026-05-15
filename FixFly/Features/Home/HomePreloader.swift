import Foundation
import AVFoundation
import UIKit

final class HomePreloader {
    static let shared = HomePreloader()
    private init() {}

    private var retainedAssets: [AVURLAsset] = []

    func preloadHomeContent() async {
        do {
            let home = try await HomeAPI.shared.fetchHome()

            let mediaURLs = collectMediaURLs(from: home)

            async let imageTask: Void = preloadImages(from: mediaURLs.images)
            async let videoTask: Void = preloadVideos(from: mediaURLs.videos)

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
                default:
                    break
                }
            }
        }
    }

    private func preloadImages(from urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
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
        }
    }

    private func preloadVideos(from urls: [URL]) async {
        retainedAssets.removeAll()

        await withTaskGroup(of: AVURLAsset?.self) { group in
            for url in urls {
                group.addTask {
                    let asset = AVURLAsset(url: url)
                    do {
                        let playable = try await asset.load(.isPlayable)
                        guard playable else {
                            print("Video not playable:", url.absoluteString)
                            return nil
                        }
                        return asset
                    } catch {
                        print("Video preload failed:", url.absoluteString)
                        return nil
                    }
                }
            }

            for await asset in group {
                if let asset {
                    retainedAssets.append(asset)
                }
            }
        }
    }

    private func unique(_ urls: [URL]) -> [URL] {
        Array(Set(urls.map(\.absoluteString))).compactMap(URL.init(string:))
    }
}
