import SwiftUI
import AVKit

struct VideoResultView: View {
    let title: String?
    let videoURL: URL
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ResultCompareViewModel()

    @State private var showShare = false
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isMuted = false
    @State private var showSuccessCheck = false
    @State private var localVideoURL: URL?
    
    @State private var videoAspectRatio: CGFloat? = nil

    init(title: String? = nil, videoURL: URL, onDelete: (() -> Void)? = nil) {
        self.title = title
        self.videoURL = videoURL
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack {
            FixFlyBackground(imageName: "fixfly_bg")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    if let player = player, let ratio = videoAspectRatio {
                        videoBlock(player: player, ratio: ratio)
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        VStack {
                            Spacer(minLength: 100)
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                            Spacer(minLength: 100)
                        }
                    }

                    actionButtons
                        .padding(.horizontal, 16)

                    ShareResultSection(
                        onDownloadTap: {
                            Task { await viewModel.saveResult(from: .remote(videoURL.absoluteString)) }
                        },
                        onShareTap: { platform in
                            prepareAndShareVideo()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            
            if showSuccessCheck {
                ZStack {
                    Color.black.opacity(0)
                        .ignoresSafeArea()
                    
                    VStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 120, height: 120)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 20)
                    .offset(y: -60)
                }
                .zIndex(100)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .navigationTitle(title ?? "Video Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: viewModel.toast) { oldValue, newValue in
            if newValue == "SUCCESS_ACTION" {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showSuccessCheck = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSuccessCheck = false
                        viewModel.toast = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let url = localVideoURL {
                ActivityView(activityItems: [url])
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            setupPlayer()
            calculateAspectRatio()
        }
        .onDisappear {
            player?.pause()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await viewModel.saveResult(from: .remote(videoURL.absoluteString)) }
                    } label: { Label("Save to Photos", systemImage: "square.and.arrow.down") }

                    Button { prepareAndShareVideo() } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func videoBlock(player: AVPlayer, ratio: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            FullScreenVideoPlayerView(player: player)
                .aspectRatio(ratio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            Button {
                isMuted.toggle()
                self.player?.isMuted = isMuted
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            .padding(14)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
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

    private var actionButtons: some View {
        Button { prepareAndShareVideo() } label: {
            Text("Share")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(videoAspectRatio == nil)
        .opacity(videoAspectRatio == nil ? 0.5 : 1.0)
    }

    private func prepareAndShareVideo() {
        Task {
            if localVideoURL != nil {
                showShare = true
                return
            }
            
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: videoURL)
                let docs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let destinationURL = docs.appendingPathComponent("fixfly_share_\(UUID().uuidString).mp4")
                
                try? FileManager.default.removeItem(at: destinationURL)
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                
                await MainActor.run {
                    self.localVideoURL = destinationURL
                    self.showShare = true
                }
            } catch {
                print("Silent fail for share preparation")
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

    private func calculateAspectRatio() {
        let asset = AVURLAsset(url: videoURL)
        Task {
            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                if let videoTrack = tracks.first {
                    let size = try await videoTrack.load(.naturalSize)
                    let transform = try await videoTrack.load(.preferredTransform)
                    
                    let isPortrait = abs(transform.b) == 1.0 || abs(transform.c) == 1.0
                    
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.3)) {
                            if isPortrait {
                                self.videoAspectRatio = size.height / size.width
                            } else {
                                self.videoAspectRatio = size.width / size.height
                            }
                        }
                    }
                }
            } catch {
                print("Failed to load video dimensions: \(error)")
                await MainActor.run {
                    withAnimation { self.videoAspectRatio = 9/16 }
                }
            }
        }
    }
}

fileprivate class VideoPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
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
