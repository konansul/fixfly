//
//  VideoResultView.swift
//  FixFly
//
//  Created by Kanan Sultanov on 21.03.26.
//

import SwiftUI
import AVKit

struct VideoResultView: View {
    let videoURL: URL

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ResultCompareViewModel()

    @State private var showShare = false
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isMuted = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                FullScreenVideoPlayerView(player: player)
                    .ignoresSafeArea()
            }
        }
        .overlay {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            isMuted.toggle()
                            player?.isMuted = isMuted
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                    Button { showShare = true } label: {
                        Text("Share")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                    shareSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: viewModel.shareItems(for: .remote(videoURL.absoluteString)))
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
        
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await viewModel.saveResult(from: .remote(videoURL.absoluteString)) }
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }

                    Button { showShare = true } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func setupPlayer() {
        let item = AVPlayerItem(url: videoURL)
        let queue = AVQueuePlayer(playerItem: item)

        self.looper = AVPlayerLooper(player: queue, templateItem: item)

        queue.isMuted = isMuted
        queue.play()

        self.player = queue
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.44, green: 0.28, blue: 1.00),
                Color(red: 0.94, green: 0.33, blue: 0.87),
                Color(red: 0.26, green: 0.67, blue: 1.00)
            ],
            startPoint: .leading, endPoint: .trailing
        )
    }

    private var shareSection: some View {
        VStack(spacing: 16) {
            Text("Share to")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))

            HStack(spacing: 22) {
                shareButton(icon: "arrow.down", title: "Download") {
                    Task { await viewModel.saveResult(from: .remote(videoURL.absoluteString)) }
                }
                shareButton(icon: "music.note", title: "TikTok") { showShare = true }
                shareButton(icon: "play.rectangle.fill", title: "YouTube") { showShare = true }
                shareButton(icon: "camera.fill", title: "Instagram") { showShare = true }
                shareButton(icon: "xmark", title: "X") { showShare = true }
            }
        }
    }

    private func shareButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .buttonStyle(.plain)
    }
}

fileprivate class VideoPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

fileprivate struct FullScreenVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> VideoPlayerUIView { VideoPlayerUIView(player: player) }
    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {}
}
