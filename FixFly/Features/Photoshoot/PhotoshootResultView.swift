//
//  PhotoshootResultView.swift
//  FixFly
//
//  Gallery of the N photos a photoshoot produced. Swipe through them, pinch to
//  zoom, save one or all to Photos, and share. Reached both from the processing
//  screen (fresh shoot) and from My Generations (a past shoot).
//

import SwiftUI

struct PhotoshootResultView: View {
    let title: String
    let urls: [String]
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var saver = ResultCompareViewModel()

    @State private var selection = 0
    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var uiImageToShare: UIImage?
    @State private var showShare = false
    @State private var isSavingAll = false
    @State private var showSuccessCheck = false

    var body: some View {
        ZStack {
            FixFlyBackground(imageName: "fixfly_bg")
                .ignoresSafeArea()

            // Scrollable, like the single-photo result screen.
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    pager
                    thumbnailStrip
                    saveAllButton
                        .padding(.horizontal, 16)

                    ShareResultSection(
                        onDownloadTap: {
                            Task { await saver.saveResult(from: .remote(currentUrl)) }
                        },
                        onShareTap: { _ in shareCurrent() }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .padding(.top, 10)
            }

            if showSuccessCheck { successOverlay }
            if let toast = saver.toast, toast != "SUCCESS_ACTION", !showSuccessCheck {
                toastView(toast)
            }
        }
        .navigationTitle(title.isEmpty ? "Your Photoshoot" : title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShare) {
            if let image = uiImageToShare {
                ActivityView(activityItems: [image])
                    .presentationDetents([.medium, .large])
            }
        }
        .onChange(of: saver.toast) { _, newValue in
            if newValue == "SUCCESS_ACTION" {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showSuccessCheck = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSuccessCheck = false
                        saver.toast = nil
                    }
                }
            }
        }
        .onChange(of: selection) { _, _ in
            // Reset zoom when swiping to another photo.
            zoom = 1; lastZoom = 1
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await saver.saveResult(from: .remote(currentUrl)) }
                    } label: { Label("Save this photo", systemImage: "square.and.arrow.down") }

                    Button { saveAll() } label: {
                        Label("Save all \(urls.count)", systemImage: "square.and.arrow.down.on.square")
                    }

                    Button { shareCurrent() } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    if let onDelete {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: { Label("Delete set", systemImage: "trash") }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var currentUrl: String {
        urls.indices.contains(selection) ? urls[selection] : (urls.first ?? "")
    }

    // MARK: - Pieces

    private var pager: some View {
        TabView(selection: $selection) {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()   // fills width — no side gaps
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.4))
                    default:
                        MediaLoadingPlaceholder()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 520)
                // Rounded corners; single clip (no extra .clipped()) avoids the
                // square-flash during the paging swipe.
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .scaleEffect(index == selection ? zoom : 1)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in zoom = min(max(lastZoom * value, 1.0), 4.0) }
                        .onEnded { _ in lastZoom = zoom }
                )
                .padding(.horizontal, 16)   // don't let the photo touch the screen edges
                .tag(index)
            }
        }
        .frame(height: 520)
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selection = index }
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
                                .stroke(selection == index ? FixFlyGradient.accent : Color.white.opacity(0.12),
                                        lineWidth: selection == index ? 2.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var saveAllButton: some View {
        Button { saveAll() } label: {
            HStack(spacing: 8) {
                if isSavingAll { ProgressView().tint(.white) }
                Image(systemName: "square.and.arrow.down.on.square")
                Text(isSavingAll ? "Saving…" : "Save all \(urls.count) photos")
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(FixFlyGradient.linear)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isSavingAll)
    }

    private var successOverlay: some View {
        VStack {
            Image(systemName: "checkmark")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 120, height: 120)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.2), radius: 20)
        .zIndex(100)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    private func toastView(_ toast: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                if toast.contains("Saving") || toast.contains("Downloading") { ProgressView().tint(.white) }
                Text(toast)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.bottom, 30)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .zIndex(10)
    }

    // MARK: - Actions

    private func saveAll() {
        guard !isSavingAll else { return }
        isSavingAll = true
        Task {
            for url in urls {
                await saver.saveResult(from: .remote(url))
            }
            await MainActor.run { isSavingAll = false }
        }
    }

    private func shareCurrent() {
        Task {
            guard let url = URL(string: currentUrl) else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.uiImageToShare = image
                        self.showShare = true
                    }
                }
            } catch { }
        }
    }
}
