//
//  RemoteCard.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//

import SwiftUI
import AVKit

/// Единый плейсхолдер загрузки медиа: полностью прозрачный, без спиннера.
/// Сквозь него виден фон приложения; реальный контент (фото или видео)
/// появляется сам, как только подгрузится. Прозрачность выбрана намеренно,
/// чтобы фото и видео в момент загрузки выглядели одинаково и не мелькали
/// серыми/чёрными прямоугольниками.
struct MediaLoadingPlaceholder: View {
    var body: some View {
        Color.clear
    }
}

struct HorizontalRemoteCards: View {
    let items: [RemoteCardItem]
    let onTap: (RemoteCardItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    Button {
                        onTap(item)
                    } label: {
                        RoundedRemoteMediaCard(item: item)
                            .allowsHitTesting(false)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
        }
    }
}

struct RoundedRemoteMediaCard: View {
    let item: RemoteCardItem

    private var displayTitle: String? {
        return item.styleId
    }

    var body: some View {
        ZStack {
            switch item.mediaType {
            case .image:
                if let url = URL(string: item.mediaUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            MediaLoadingPlaceholder()
                        }
                    }
                } else {
                    fallback
                }

            case .video:
                if let poster = item.posterUrl,
                   let posterURL = URL(string: poster) {
                    AsyncImage(url: posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            ZStack {
                                image
                                    .resizable()
                                    .scaledToFill()

                            }
                        default:
                            MediaLoadingPlaceholder()
                        }
                    }
                } else if let videoURL = URL(string: item.mediaUrl) {
                    ZStack {
                        CachedVideoView(remoteURL: videoURL)
                    }
                } else {
                    videoFallback
                }
            }
        }
        // A touch smaller than the original 152×202, but bigger than the very
        // compact 134×178 — the sweet spot.
        .frame(width: 144, height: 192)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        // Template name — bottom-left, plain (no dark background), a soft shadow
        // keeps it legible over the artwork.
        .overlay(alignment: .bottomLeading) {
            if let name = displayTitle, name.lowercased() != "none" {
                Text(name.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.65), radius: 3, x: 0, y: 1)
                    .padding(10)
            }
        }
    }

    private var fallback: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.black)
    }

    private var videoFallback: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .overlay(
                ZStack {
                    Image(systemName: "video")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            )
    }
}


final class CardPlayerContainerView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var currentURL: URL?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func configure(url: URL) {
        guard currentURL != url else { return }
        currentURL = url

        NotificationCenter.default.removeObserver(self)

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds

        self.playerLayer?.removeFromSuperlayer()
        self.layer.addSublayer(layer)

        self.player = player
        self.playerLayer = layer

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loopVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        player.play()
    }

    @objc private func loopVideo() {
        player?.seek(to: .zero)
        player?.play()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
