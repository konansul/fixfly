import SwiftUI
import AVKit

struct TemplateFeedView: View {
    let templates: [RemoteCardItem]
    let sectionId: String
    let currentIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoPicker = false

    @State private var selectedImage: UIImage?
    @State private var resultUIImage: UIImage?
    @State private var resultVideoURL: URL?
    
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showResult = false
    
    @State private var scrollPosition: String?
    @State private var activeTemplate: RemoteCardItem?
    @State private var showCoinsSheet = false

    init(templates: [RemoteCardItem], sectionId: String, currentIndex: Int) {
        self.templates = templates
        self.sectionId = sectionId
        self.currentIndex = currentIndex
        
        let initialId = templates.indices.contains(currentIndex) ? templates[currentIndex].id : templates.first?.id
        self._scrollPosition = State(initialValue: initialId)
        
        if let initialId = initialId {
            self._activeTemplate = State(initialValue: templates.first(where: { $0.id == initialId }))
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(templates) { template in
                        TemplateFullScreenPage(
                            template: template,
                            isActive: template.id == scrollPosition
                        )
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(template.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPosition)
            .onChange(of: scrollPosition) { newId in
                if let newId = newId, let found = templates.first(where: { $0.id == newId }) {
                    withAnimation {
                        activeTemplate = found
                    }
                }
            }
            .ignoresSafeArea()

            gradientOverlay

            VStack {
                Spacer()
                if activeTemplate != nil {
                    bottomSection
                }
            }

            if isProcessing {
                processingOverlay
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                self.selectedImage = image
                Task { await processImage(image) }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showCoinsSheet) {
            CoinsWalletSheetView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $showResult) {
            if let videoURL = resultVideoURL {
                VideoResultView(videoURL: videoURL)
                    .toolbar(.hidden, for: .tabBar)
            } else if let before = selectedImage, let after = resultUIImage {
                ResultCompareView(before: before, after: after)
                    .toolbar(.hidden, for: .tabBar)
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCoinsSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.yellow)

                        Text("\(WalletManager.shared.coins)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private var gradientOverlay: some View {
        VStack {
            LinearGradient(
                colors: [Color.black.opacity(0.4), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            
            Spacer()
            
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.6), Color.black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var bottomSection: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(activeTemplate?.styleId?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Awesome Effect")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 2)

            HStack(spacing: 12) {
                badge(icon: activeTemplate?.mediaType == .video ? "video" : "photo",
                      text: activeTemplate?.mediaType == .video ? "1 video" : "1 photo")
                badge(icon: "speaker.wave.2", text: "With sound")
                badge(icon: "bitcoinsign.circle.fill",
                      text: activeTemplate?.mediaType == .video ? "600 coins" : "150 coins",
                      iconColor: .yellow)
            }
            .padding(.bottom, 10)

            Button {
                showPhotoPicker = true
            } label: {
                Text(activeTemplate?.mediaType == .video ? "Create Video" : "Create Photo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.25, blue: 1.0),
                                Color(red: 1.0, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .disabled(isProcessing)
        }
        .padding(.bottom, 40)
    }

    private func badge(icon: String, text: String, iconColor: Color = .white) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
            Text(text)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)

                Text("Processing…")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text("This usually takes a few seconds")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
        }
    }

    private func processImage(_ input: UIImage) async {
        guard let template = activeTemplate else { return }

        await MainActor.run {
            isProcessing = true
            errorMessage = nil
            resultUIImage = nil
            resultVideoURL = nil
        }

        let isVideo = (template.mediaType == .video)
        let path = endpointPath(for: sectionId, isVideo: isVideo)
        
        var extra: [String: String] = [:]
        extra["style_id"] = template.styleId ?? template.id

        do {
            if isVideo {
                let outputURL = try await MultipartAPI.shared.processImageToVideo(
                    endpointPath: path,
                    image: input,
                    extraFields: extra
                )
                await WalletManager.shared.refreshBalance()
                await MainActor.run {
                    resultVideoURL = outputURL
                    isProcessing = false
                    showResult = true
                }
            } else {
                let outputImage = try await MultipartAPI.shared.processImage(
                    endpointPath: path,
                    image: input,
                    extraFields: extra,
                    accept: "image/png"
                )
                await WalletManager.shared.refreshBalance()
                await MainActor.run {
                    resultUIImage = outputImage
                    isProcessing = false
                    showResult = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
            }
        }
    }

    private func endpointPath(for sectionId: String, isVideo: Bool) -> String {
        if isVideo { return "/v1/generate-template-video" }
        switch sectionId {
        case "anime": return "/v1/anime-avatar"
        case "enhance": return "/v1/enhance-photo"
        case "restore": return "/v1/restore-old-photo"
        default: return "/v1/anime-avatar"
        }
    }
}

private struct TemplateFullScreenPage: View {
    let template: RemoteCardItem
    let isActive: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let posterUrlString = template.posterUrl, let posterUrl = URL(string: posterUrlString) {
                AsyncImage(url: posterUrl) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill().ignoresSafeArea()
                    }
                }
            }

            if let url = URL(string: template.mediaUrl) {
                if template.mediaType == .video || template.mediaUrl.hasSuffix(".mp4") || template.mediaUrl.hasSuffix(".mov") {
                    LoopingVideoView(url: url, isActive: isActive)
                        .ignoresSafeArea()
                } else {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill().ignoresSafeArea()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }
}
