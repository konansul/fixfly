//
//  PhotoshootDetailView.swift
//  FixFly
//
//  Tapped from the catalog. Shows the 5 example photos for a template, then the
//  user uploads ONE selfie and gets their own 5-photo set back. No upload-slot
//  preview on the card — the examples ARE the pitch.
//

import SwiftUI

struct PhotoshootDetailView: View {
    let template: PhotoshootTemplateDTO

    @Environment(\.dismiss) private var dismiss

    @State private var exampleIndex = 0
    @State private var showPhotoPicker = false
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showPaywall = false

    @State private var processingTaskId: String?
    @State private var resultUrls: [String] = []
    @State private var showResult = false

    var body: some View {
        ZStack {
            FixFlyBackground(imageName: "fixfly_bg")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    examplePager
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    thumbnailStrip

                    header
                        .padding(.horizontal, 20)

                    Spacer(minLength: 8)
                }
            }
            // The button lives in the bottom safe-area inset, so the scroll content
            // is pushed up above it instead of being covered — the badges used to
            // sit underneath the button.
            .safeAreaInset(edge: .bottom) {
                createButton
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .background(
                        LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                       startPoint: .top, endPoint: .bottom)
                            .allowsHitTesting(false)
                    )
            }

            if isUploading { uploadingOverlay }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                Task { await startGeneration(image) }
            }
            .ignoresSafeArea()
        }
        .sheet(item: $processingTaskId) { taskId in
            PhotoProcessingView(taskId: taskId, onComplete: { _ in
                // output_url is just the anchor; fetch the full 5-photo set.
                Task {
                    let urls = await PhotoshootAPI.shared.fetchOutputs(taskId: taskId)
                    await MainActor.run {
                        self.processingTaskId = nil
                        NotificationCenter.default.post(name: .generationNeedsRefresh, object: nil)
                        self.resultUrls = urls
                        self.showResult = true
                    }
                }
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
        .navigationDestination(isPresented: $showResult) {
            PhotoshootResultView(title: template.name, urls: resultUrls)
                .toolbar(.hidden, for: .tabBar)
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

    private var examplePager: some View {
        TabView(selection: $exampleIndex) {
            ForEach(Array(template.examples.enumerated()), id: \.offset) { index, url in
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo").font(.system(size: 30)).foregroundStyle(.white.opacity(0.4))
                    default:
                        MediaLoadingPlaceholder()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 460)
                // Rounded via a single clip (no extra .clipped()) — doesn't flash
                // square during the paging swipe.
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .tag(index)
            }
        }
        .frame(height: 460)
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(template.examples.enumerated()), id: \.offset) { index, url in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { exampleIndex = index }
                    } label: {
                        AsyncImage(url: URL(string: url)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.white.opacity(0.08)
                            }
                        }
                        .frame(width: 54, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(exampleIndex == index ? FixFlyGradient.accent : Color.white.opacity(0.12),
                                        lineWidth: exampleIndex == index ? 2.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(template.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                badge(icon: "photo.stack", text: "\(template.photoCount) photos")
                badge(icon: "bitcoinsign.circle.fill", text: "\(template.cost) coins", iconColor: .yellow)
                AIDisclosureFootnote(provider: .gemini)
            }

            Text("Upload one clear selfie. We keep only your face — the outfit, scene and lighting are created fresh.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    private var createButton: some View {
        Button {
            showPhotoPicker = true
        } label: {
            Text("Create my photoshoot")
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

    private func startGeneration(_ selfie: UIImage) async {
        // Guests browse; generating requires Sign in with Apple.
        let authed = await MainActor.run { AuthStore.shared.requireSignIn() }
        guard authed else { return }

        await MainActor.run {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isUploading = true
            errorMessage = nil
        }

        AppAnalytics.track(.generateStarted(kind: "photo", template: template.id))

        do {
            let taskId = try await PhotoshootAPI.shared.start(templateId: template.id, selfie: selfie)
            await WalletManager.shared.refreshBalance()
            await MainActor.run {
                isUploading = false
                self.processingTaskId = taskId
            }
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
