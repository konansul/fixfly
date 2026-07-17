//
//  DuoDetailView.swift
//  FixFly
//
//  Tapped from the Together section. Shows a looping preview, then the user fills
//  TWO upload slots (photo 1 + photo 2) and gets one video of them together back.
//

import SwiftUI
import AVFoundation

struct DuoDetailView: View {
    let template: DuoTemplateDTO

    @Environment(\.dismiss) private var dismiss

    @State private var photo1: UIImage?
    @State private var photo2: UIImage?

    @State private var showPicker = false
    @State private var activeSlot = 1

    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showPaywall = false

    @State private var processingTaskId: String?
    @State private var resultVideoURL: URL?
    @State private var showResult = false

    private var needsTwo: Bool { template.uploads >= 2 }
    private var requiredChosen: Bool { photo1 != nil && (!needsTwo || photo2 != nil) }
    private var hasEmptySlot: Bool { photo1 == nil || (needsTwo && photo2 == nil) }

    var body: some View {
        ZStack {
            FixFlyBackground(imageName: "fixfly_bg")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    heroPreview
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    header
                        .padding(.horizontal, 20)

                    if hasEmptySlot {
                        addPhotoButton
                            .padding(.horizontal, 16)
                    }

                    uploadSlots
                        .padding(.horizontal, 16)

                    Spacer(minLength: 8)
                }
            }
            // The CTA only appears once both photos are in — no dead "Add two photos"
            // button sitting over the empty slots. Until then the slots are the focus.
            .safeAreaInset(edge: .bottom) {
                if requiredChosen {
                    createButton
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .background(
                            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                           startPoint: .top, endPoint: .bottom)
                                .allowsHitTesting(false)
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: requiredChosen)

            if isUploading { uploadingOverlay }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            // Let the Together preview play with sound even when the phone's
            // silent switch is on, matching the video-template detail screen.
            // Activating the session can block, so do it off the main thread.
            DispatchQueue.global(qos: .userInitiated).async {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try? AVAudioSession.sharedInstance().setActive(true)
            }
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                if activeSlot == 1 { photo1 = image } else { photo2 = image }
            }
            .ignoresSafeArea()
        }
        .sheet(item: $processingTaskId) { taskId in
            PhotoProcessingView(taskId: taskId, onComplete: { outputUrl in
                self.processingTaskId = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .generationNeedsRefresh, object: nil)
                    self.resultVideoURL = URL(string: outputUrl)
                    self.showResult = true
                }
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
        .navigationDestination(isPresented: $showResult) {
            if let videoURL = resultVideoURL {
                VideoResultView(title: template.name, videoURL: videoURL)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Pieces

    private var heroPreview: some View {
        Group {
            if let url = URL(string: template.previewUrl) {
                LoopingVideoView(url: url, isActive: true, isMuted: false)
            } else {
                AsyncImage(url: URL(string: template.posterUrl)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        MediaLoadingPlaceholder()
                    }
                }
            }
        }
        .frame(height: 420)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(template.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                badge(icon: "video.fill", text: "1 video")
                badge(icon: "bitcoinsign.circle.fill", text: "\(template.cost) coins", iconColor: .yellow)
                AIDisclosureFootnote(provider: .gemini)
            }

            Text(needsTwo
                 ? "Upload two clear face photos. We keep both faces and create the scene fresh."
                 : "Upload one photo with both of you in it. We keep the whole photo — you just hug.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    // Explicit CTA under the instruction text; opens the picker for the next empty
    // slot. The First/Second slots below stay as the visible block.
    private var addPhotoButton: some View {
        Button {
            activeSlot = (photo1 == nil) ? 1 : 2
            showPicker = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "photo.badge.plus")
                Text(photo1 == nil ? "Add photo" : "Add second photo")
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(FixFlyGradient.linear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var uploadSlots: some View {
        HStack(spacing: 12) {
            slot(image: photo1, label: template.slot1Label, index: 1)
            if needsTwo {
                slot(image: photo2, label: template.slot2Label, index: 2)
            }
        }
    }

    private func slot(image: UIImage?, label: String, index: Int) -> some View {
        Button {
            activeSlot = index
            showPicker = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                        Text(label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                    .padding(8)
                }
            }
            .frame(height: 210)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(image == nil ? Color.white.opacity(0.18) : FixFlyGradient.accent,
                            style: StrokeStyle(lineWidth: image == nil ? 1.5 : 2,
                                               dash: image == nil ? [6] : []))
            )
            .overlay(alignment: .bottomLeading) {
                if image != nil {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2)
                        .padding(8)
                }
            }
            .overlay(alignment: .topTrailing) {
                if image != nil {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, .black.opacity(0.4))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var createButton: some View {
        Button {
            Task { await startGeneration() }
        } label: {
            Text("Create video")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(FixFlyGradient.linear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
    }

    private var uploadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().tint(.white)
                Text("Uploading...")
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .medium))
            }
        }
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

    // MARK: - Generation

    private func startGeneration() async {
        guard let p1 = photo1 else { return }
        let photos: [UIImage] = needsTwo ? [p1, photo2].compactMap { $0 } : [p1]
        guard photos.count == template.uploads else { return }

        let authed = await MainActor.run { AuthStore.shared.requireSignIn() }
        guard authed else { return }

        await MainActor.run {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isUploading = true
            errorMessage = nil
        }

        AppAnalytics.track(.generateStarted(kind: "video", template: template.id))

        do {
            let taskId = try await DuoAPI.shared.start(templateId: template.id, photos: photos)
            await WalletManager.shared.refreshBalance()
            await MainActor.run {
                isUploading = false
                self.processingTaskId = taskId
            }
        } catch is CancellationError {
            // User declined the AI data-sharing consent — abort quietly.
            await MainActor.run { isUploading = false }
        } catch {
            await MainActor.run {
                isUploading = false
                let msg = error.localizedDescription
                if msg.contains("402") || msg.lowercased().contains("not enough coins") {
                    showPaywall = true
                } else {
                    errorMessage = "Oops! Something went wrong. Please try again."
                }
            }
        }
    }
}
