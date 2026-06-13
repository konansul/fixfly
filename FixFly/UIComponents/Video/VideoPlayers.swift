//
//  VideoPlayers.swift
//  FixFly
//

import SwiftUI
import AVFoundation
import UIKit

struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    let isActive: Bool
    var isMuted: Bool = true

    func makeUIView(context: Context) -> SafePlayerContainerView {
        SafePlayerContainerView()
    }

    func updateUIView(_ uiView: SafePlayerContainerView, context: Context) {
        uiView.update(url: url, isActive: isActive, isMuted: isMuted)
    }

    static func dismantleUIView(_ uiView: SafePlayerContainerView, coordinator: ()) {
        uiView.destroyPlayer()
    }
}

struct LoopingCardVideoView: View {
    let url: URL
    var isMuted: Bool = true
    @State private var isVisible = false

    var body: some View {
        LoopingVideoView(url: url, isActive: isVisible, isMuted: isMuted)
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
    }
}

struct LocalLoopingVideoView: UIViewRepresentable {
    let videoName: String
    let fileExtension: String
    var isMuted: Bool = true

    func makeUIView(context: Context) -> SafePlayerContainerView {
        SafePlayerContainerView()
    }

    func updateUIView(_ uiView: SafePlayerContainerView, context: Context) {
        if let url = Bundle.main.url(forResource: videoName, withExtension: fileExtension) {
            uiView.update(url: url, isActive: true, isMuted: isMuted)
        }
    }

    static func dismantleUIView(_ uiView: SafePlayerContainerView, coordinator: ()) {
        uiView.destroyPlayer()
    }
}

struct CachedVideoView: View {
    let remoteURL: URL
    var isMuted: Bool = true
    @State private var localURL: URL?

    var body: some View {
        ZStack {
            if let localURL = localURL {
                LoopingCardVideoView(url: localURL, isMuted: isMuted)
            } else {
                Color.clear
            }
        }
        .task {
            localURL = await VideoCacheManager.shared.getCachedURL(for: remoteURL)
        }
    }
}

final class SafePlayerContainerView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    private var currentURL: URL?
    
    // ДОБАВЛЕНО: Сохраняем текущее состояние активности
    private var isActiveState: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        // При уходе в фон система ставит плееры на паузу (а после долгого фона
        // отбирает декодеры, переводя item в .failed) — сами они не оживают.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appDidBecomeActive() {
        guard isActiveState, let player = queuePlayer else { return }
        if player.status == .failed || player.currentItem?.status == .failed {
            // Декодер отобрали — плеер уже не реанимировать, пересоздаём.
            if let url = currentURL {
                let muted = player.isMuted
                currentURL = nil
                setupPlayer(url: url, isMuted: muted)
            }
        } else if player.timeControlStatus != .playing {
            player.play()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func update(url: URL, isActive: Bool, isMuted: Bool) {
        self.isActiveState = isActive // Запоминаем состояние

        if currentURL != url {
            setupPlayer(url: url, isMuted: isMuted)
        }

        guard let player = queuePlayer else { return }

        // ДВОЙНАЯ ЗАЩИТА: Если видео не на экране, ЖЕСТКО отключаем звук, даже если isMuted в UI передается как false
        let targetMutedState = isActive ? isMuted : true
        if player.isMuted != targetMutedState {
            player.isMuted = targetMutedState
        }

        // Управляем паузой/воспроизведением
        if isActive {
            if player.timeControlStatus != .playing {
                player.play()
            }
        } else {
            if player.timeControlStatus != .paused {
                player.pause()
            }
        }
    }

    private func setupPlayer(url: URL, isMuted: Bool) {
        destroyPlayer()
        currentURL = url

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let player = AVQueuePlayer(playerItem: item)

        // Изначально глушим звук, если плеер создается не для активного экрана
        player.isMuted = self.isActiveState ? isMuted : true
        player.actionAtItemEnd = .none
        player.automaticallyWaitsToMinimizeStalling = false

        playerLooper = AVPlayerLooper(player: player, templateItem: item)

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds

        self.layer.addSublayer(layer)

        queuePlayer = player
        playerLayer = layer

        Task {
            do {
                let isPlayable = try await asset.load(.isPlayable)
                
                if isPlayable {
                    await MainActor.run {
                        // ИСПРАВЛЕНО: Запускаем только если после загрузки это видео ВСЁ ЕЩЁ активное
                        if self.isActiveState {
                            if self.queuePlayer?.timeControlStatus != .playing {
                                self.queuePlayer?.play()
                            }
                        }
                    }
                }
            } catch {
                print("Failed to load video asset: \(error.localizedDescription)")
            }
        }
    }

    func destroyPlayer() {
        queuePlayer?.pause()
        queuePlayer?.removeAllItems()
        playerLayer?.removeFromSuperlayer()

        playerLooper = nil
        queuePlayer = nil
        playerLayer = nil
        currentURL = nil
    }
}
