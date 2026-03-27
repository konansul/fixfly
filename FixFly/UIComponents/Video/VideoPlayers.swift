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

    func makeUIView(context: Context) -> SafePlayerContainerView {
        SafePlayerContainerView()
    }

    func updateUIView(_ uiView: SafePlayerContainerView, context: Context) {
        uiView.update(url: url, isActive: isActive)
    }

    static func dismantleUIView(_ uiView: SafePlayerContainerView, coordinator: ()) {
        uiView.destroyPlayer()
    }
}


struct LoopingCardVideoView: View {
    let url: URL
    @State private var isVisible = false

    var body: some View {
        // Используем твой базовый LoopingVideoView, но передаем ему переменную isVisible
        LoopingVideoView(url: url, isActive: isVisible)
            .onAppear {
                // Как только карточка появляется на экране — запускаем видео
                isVisible = true
            }
            .onDisappear {
                // Как только карточка уходит с экрана — ставим на паузу!
                // Это спасет память и батарею.
                isVisible = false
            }
    }
}



struct LocalLoopingVideoView: UIViewRepresentable {

    let videoName: String
    let fileExtension: String

    func makeUIView(context: Context) -> SafePlayerContainerView {
        SafePlayerContainerView()
    }

    func updateUIView(_ uiView: SafePlayerContainerView, context: Context) {

        if let url = Bundle.main.url(forResource: videoName, withExtension: fileExtension) {
            uiView.update(url: url, isActive: true)
        }
    }

    static func dismantleUIView(_ uiView: SafePlayerContainerView, coordinator: ()) {
        uiView.destroyPlayer()
    }
}

struct CachedVideoView: View {
    let remoteURL: URL
    @State private var localURL: URL?

    var body: some View {
        ZStack {
            if let localURL = localURL {
                LoopingCardVideoView(url: localURL)
            } else {
                Color.white.opacity(0.05)
                ProgressView().tint(.white)
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

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }


    func update(url: URL, isActive: Bool) {

        if currentURL != url {
            setupPlayer(url: url)
        }

        guard let player = queuePlayer else { return }

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

    // MARK: Setup Player

    private func setupPlayer(url: URL) {

        destroyPlayer()

        currentURL = url

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        let player = AVQueuePlayer(playerItem: item)

        player.isMuted = true
        player.actionAtItemEnd = .none

        // улучшает скролл
        player.automaticallyWaitsToMinimizeStalling = false

        playerLooper = AVPlayerLooper(player: player, templateItem: item)

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds

        self.layer.addSublayer(layer)

        queuePlayer = player
        playerLayer = layer

        asset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in

            DispatchQueue.main.async {

                guard let self = self else { return }

                if self.queuePlayer?.timeControlStatus != .playing {
                    self.queuePlayer?.play()
                }
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
