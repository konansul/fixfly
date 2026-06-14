import SwiftUI
import AVKit

struct TemplateFeedView: View {
    let templates: [RemoteCardItem]
    let sectionId: String
    let currentIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoPicker = false

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
    
    @State private var isMuted = false

    // TikTok-style "clear mode": hold anywhere to hide the UI and watch the
    // video clean; releasing the finger brings everything back.
    @State private var isUIHidden = false

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

            // TikTok-подобный вертикальный скролл
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(templates) { template in
                        TemplateFullScreenPage(
                            template: template,
                            isActive: template.id == scrollPosition,
                            isMuted: isMuted // Передаем состояние звука во вью
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
            // Удержание пальца — прячем весь интерфейс (clear mode), отпустил — вернули.
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.35)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onChanged { value in
                        if case .second(true, nil) = value, !isUIHidden {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) { isUIHidden = true }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.2)) { isUIHidden = false }
                    }
            )

            // Усиленное затемнение
            gradientOverlay
                .opacity(isUIHidden ? 0 : 1)

            // Поверх контента выводим интерфейс управления
            VStack(spacing: 0) {
                Spacer()

                // Нижняя панель
                if let active = activeTemplate {
                    bottomSection(for: active)
                }
            }
            .opacity(isUIHidden ? 0 : 1)
            .allowsHitTesting(!isUIHidden)

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
        .toolbar(isUIHidden ? .hidden : .visible, for: .navigationBar)
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
        .onAppear {
            // ВАЖНО: Разрешаем звуку играть, даже если айфон в беззвучном режиме.
            // Активация сессии может блокировать поток, поэтому уводим её с main.
            DispatchQueue.global(qos: .userInitiated).async {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try? AVAudioSession.sharedInstance().setActive(true)
            }

            prefetchModelImages()
            AppAnalytics.track(.templateOpened(template: activeTemplate?.styleId))
        }
    }

    /// Заранее скачивает фото моделей (`modelUrl`) всех темплейтов в общий
    /// URLCache. Фото показывается только для активного темплейта, поэтому без
    /// префетча оно грузится лишь после долистывания. `AsyncImage` использует
    /// `URLSession.shared`/`URLCache.shared`, так что прогретый кэш отдаётся
    /// этим же `AsyncImage` моментально — фото уже на месте к моменту свайпа.
    private func prefetchModelImages() {
        let urls = templates
            .compactMap { $0.modelUrl }
            .compactMap { URL(string: $0) }

        for url in urls {
            let request = URLRequest(url: url)
            guard URLCache.shared.cachedResponse(for: request) == nil else { continue }
            URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
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
                colors: [
                    Color.clear,
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.9),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 450)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func bottomSection(for template: RemoteCardItem) -> some View {
        VStack(alignment: .center, spacing: 14) {
            
            if template.modelUrl != nil || template.actualResultType == .video {
                HStack(alignment: .bottom, spacing: 8) {
                    if let modelFaceUrl = template.modelUrl {
                        AsyncImage(url: URL(string: modelFaceUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Color.clear
                            }
                        }
                        .frame(width: 90, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)

                        HandDrawnArrow()
                            .offset(y: -30)
                    }

                    Spacer()

                    // Кнопка звука — на одном уровне с карточкой-референсом.
                    if template.actualResultType == .video {
                        Button {
                            withAnimation { isMuted.toggle() }
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Text(template.styleId?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Awesome Effect")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .id(template.id)

            HStack(spacing: 10) {
                badge(icon: template.actualResultType == .video ? "video" : "photo",
                      text: template.actualResultType == .video ? "1 video" : "1 photo")
                
                if template.actualResultType == .video {
                    badge(icon: isMuted ? "speaker.slash.fill" : "speaker.wave.2",
                          text: isMuted ? "Muted" : "With sound")
                }
                
                badge(icon: "bitcoinsign.circle.fill",
                      text: template.actualResultType == .video ? "600 coins" : "150 coins",
                      iconColor: .yellow)
            }
            .id(template.id.appending("_badges"))

            Button {
                // Сразу открываем пикер, без промежуточного окна
                showPhotoPicker = true
            } label: {
                Text(template.actualResultType == .video ? "Create Video" : "Create Photo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(FixFlyGradient.linear)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .disabled(isUploading)
            .id(template.id.appending("_btn"))
        }
        .padding(.bottom, 30)
    }

    private func badge(icon: String, text: String, iconColor: Color = .white) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(iconColor)
            Text(text)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }

    private func startGeneration(_ input: UIImage) async {
        guard let template = activeTemplate else { return }

        await MainActor.run {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isUploading = true
            errorMessage = nil
        }

        let isVideo = (template.actualResultType == .video)
        AppAnalytics.track(.generateStarted(kind: isVideo ? "video" : "photo", template: template.styleId))
        let path = isVideo ? "/v1/generate-veo-video" : "/v1/generate-nano-banana"
        
        var extra: [String: String] = [:]
        extra["prompt"] = template.prompt ?? "Animate this photo beautifully"
        extra["style"] = template.styleId ?? "None"
        
        let ratio = input.size.width / input.size.height
        
        if isVideo {
            extra["aspect_ratio"] = ratio > 1.0 ? "16:9" : "9:16"
        } else {
            if ratio >= 1.5 { extra["aspect_ratio"] = "16:9" }
            else if ratio >= 1.15 { extra["aspect_ratio"] = "4:3" }
            else if ratio >= 0.85 { extra["aspect_ratio"] = "1:1" }
            else if ratio >= 0.65 { extra["aspect_ratio"] = "3:4" }
            else { extra["aspect_ratio"] = "9:16" }
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
    let isMuted: Bool // Принимаем параметр звука

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = URL(string: template.mediaUrl) {
                if template.mediaType == .video || template.mediaUrl.hasSuffix(".mp4") || template.mediaUrl.hasSuffix(".mov") {
                    
                    // Передаем isMuted в плеер
                    LoopingVideoView(url: url, isActive: isActive, isMuted: isMuted)
                        .ignoresSafeArea()
                        
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()
                        case .failure:
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                        default:
                            Color.clear
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }
}

struct HandDrawnArrow: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 2, y: 52))
            path.addQuadCurve(to: CGPoint(x: 33, y: 2), control: CGPoint(x: 15, y: 20))
            
            path.move(to: CGPoint(x: 33, y: 2))
            path.addLine(to: CGPoint(x: 21, y: 5))
            
            path.move(to: CGPoint(x: 33, y: 2))
            path.addLine(to: CGPoint(x: 30, y: 14))
        }
        .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .frame(width: 35, height: 55)
        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
    }
}
