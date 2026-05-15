import SwiftUI
import AVKit

struct TemplateFeedView: View {
    let templates: [RemoteCardItem]
    let sectionId: String
    let currentIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoPicker = false
    @State private var showGuidelinesSheet = false

    @State private var selectedImage: UIImage?
    @State private var finalResultImageUrl: String?
    @State private var resultVideoURL: URL?
    
    @State private var processingTaskId: String?
    
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showResult = false
    
    @State private var scrollPosition: String?
    @State private var activeTemplate: RemoteCardItem?
    @State private var showCoinsSheet = false
    
    @State private var showPaywall = false

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
            .onChange(of: scrollPosition) { oldValue, newId in
                if let newId = newId, let found = templates.first(where: { $0.id == newId }) {
                    withAnimation(.easeInOut(duration: 0.15)) {
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

            if isUploading {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Uploading...")
                            .foregroundStyle(.white)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
        }
        .sheet(isPresented: $showGuidelinesSheet) {
            PhotoGuidelinesSheetView {
                showPhotoPicker = true
            }
            .presentationDetents([.fraction(0.65)])
            .presentationDragIndicator(.visible)
            .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                self.selectedImage = image
                Task { await startGeneration(image) }
            }
            .ignoresSafeArea()
        }
        .sheet(item: $processingTaskId) { taskId in
            PhotoProcessingView(taskId: taskId, onComplete: { outputUrl in
                self.processingTaskId = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .generationNeedsRefresh, object: nil)
                    if self.activeTemplate?.actualResultType == .video {
                        self.resultVideoURL = URL(string: outputUrl)
                    } else {
                        self.finalResultImageUrl = outputUrl
                    }
                    self.showResult = true
                }
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCoinsSheet) {
            CoinsWalletSheetView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $showResult) {
            if let videoURL = resultVideoURL {
                VideoResultView(videoURL: videoURL)
                    .toolbar(.hidden, for: .tabBar)
            } else if let before = selectedImage, let afterUrl = finalResultImageUrl {
                ResultCompareView(title: "", before: before, afterURL: afterUrl)
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
                    CoinsBadge()
                }
                .buttonStyle(.plain)
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
                .id(activeTemplate?.id)

            HStack(spacing: 12) {
                badge(icon: activeTemplate?.actualResultType == .video ? "video" : "photo",
                      text: activeTemplate?.actualResultType == .video ? "1 video" : "1 photo")
                
                if activeTemplate?.actualResultType == .video {
                    badge(icon: "speaker.wave.2", text: "With sound")
                }
                
                badge(icon: "bitcoinsign.circle.fill",
                      text: activeTemplate?.actualResultType == .video ? "600 coins" : "150 coins",
                      iconColor: .yellow)
            }
            .padding(.bottom, 10)
            .id(activeTemplate?.id.appending("_badges"))

            Button {
                if SessionManager.shared.hasSeenPhotoGuidelinesThisSession {
                    showPhotoPicker = true
                } else {
                    showGuidelinesSheet = true
                }
            } label: {
                Text(activeTemplate?.actualResultType == .video ? "Create Video" : "Create Photo")
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
            .disabled(isUploading)
            .id(activeTemplate?.id.appending("_btn"))
        }
        .padding(.bottom, 40)
    }

    private func badge(icon: String, text: String, iconColor: Color = .white) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(iconColor)
            Text(text)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
    }

    private func startGeneration(_ input: UIImage) async {
        guard let template = activeTemplate else { return }

        await MainActor.run {
            isUploading = true
            errorMessage = nil
        }

        let isVideo = (template.actualResultType == .video)
        let path = isVideo ? "/v1/generate-veo-video" : "/v1/generate-nano-banana"
        
        var extra: [String: String] = [:]
        extra["prompt"] = template.prompt ?? "Animate this photo beautifully"
        extra["style"] = template.styleId ?? "None"
        
        let ratio = input.size.width / input.size.height
        
        if isVideo {
            extra["aspect_ratio"] = ratio > 1.0 ? "16:9" : "9:16"
            
        } else {
            if ratio >= 1.5 {
                extra["aspect_ratio"] = "16:9"
            } else if ratio >= 1.15 {
                extra["aspect_ratio"] = "4:3"
            } else if ratio >= 0.85 {
                extra["aspect_ratio"] = "1:1"
            } else if ratio >= 0.65 {
                extra["aspect_ratio"] = "3:4"
            } else {
                extra["aspect_ratio"] = "9:16"
            }
        }

        do {
            let taskId = try await MultipartAPI.shared.startBackgroundGeneration(
                endpointPath: path,
                images: [input],
                extraFields: extra
            )

            await WalletManager.shared.refreshBalance()

            await MainActor.run {
                isUploading = false
                self.processingTaskId = taskId
            }
        } catch {
                await MainActor.run {
                    isUploading = false
                    
                    let errorString = error.localizedDescription
                    
                    if errorString.contains("402") || errorString.lowercased().contains("not enough coins") {
                        showPaywall = true
                    } else {
                        errorMessage = "Oops! Something went wrong. Please try again."
                    }
                }
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
