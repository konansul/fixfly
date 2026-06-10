//
//  FeatureUploadView.swift
//  FixFly
//

import SwiftUI
import PhotosUI

struct FeatureUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: FeatureUploadViewModel

    init(config: FeatureConfig) {
        _vm = StateObject(wrappedValue: FeatureUploadViewModel(config: config))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    TopBar(
                        title: vm.config.title,
                        onBackTap: { dismiss() }
                    )

                    Text("Upload or Take a Photo")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 6)

                    HStack(spacing: 12) {
                        actionCard(
                            title: "Take Photo",
                            systemIcon: "camera.fill"
                        ) { vm.showCamera = true }

                        PhotosPicker(
                            selection: $vm.selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            actionCardView(
                                title: "Choose Gallery",
                                systemIcon: "photo.on.rectangle"
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    tipsCard
                        .padding(.horizontal, 16)

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }

            if vm.isProcessing { processingOverlay }
        }
        .sheet(isPresented: $vm.showCamera) {
            ImagePicker(sourceType: .camera) { image in
                vm.handleCameraImage(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: vm.selectedItem) { _, newItem in
            vm.handlePhotoSelection(newItem)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $vm.showResult) {
            if let before = vm.selectedUIImage, let after = vm.resultUIImage {
                ResultCompareView(title: "", before: before, after: after)
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { _ in vm.errorMessage = nil }
            )
        ) {
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)

                Text(vm.config.processingTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(vm.config.processingSubtitle)
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
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: vm.isProcessing)
    }

    private func actionCard(title: String, systemIcon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionCardView(title: title, systemIcon: systemIcon)
        }
        .buttonStyle(.plain)
        .disabled(vm.isProcessing)
        .opacity(vm.isProcessing ? 0.7 : 1.0)
    }

    private func actionCardView(title: String, systemIcon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemIcon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                        .foregroundStyle(Color.white.opacity(0.12))
                )
        )
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("For Best Results")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("Use a clear portrait with good lighting. Face should be visible and not too far.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.75))

            HStack(spacing: 10) {
                tipThumb(ok: true)
                tipThumb(ok: true)
                tipThumb(ok: false)
                tipThumb(ok: false)
            }

            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white.opacity(0.6))
                Text("No celebrity photos or explicit content.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func tipThumb(ok: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 72, height: 92)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )

            Circle()
                .fill(ok ? Color.green.opacity(0.95) : Color.red.opacity(0.95))
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: ok ? "checkmark" : "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                )
                .padding(6)
        }
    }
}

private struct TopBar: View {
    let title: String
    let onBackTap: () -> Void
    @State private var showPaywall = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBackTap) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button { showPaywall = true } label: {
                if let _ = NSClassFromString("FixFly.ProButton") {
                    ProButton()
                } else {
                    fallbackProChip
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var fallbackProChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.system(size: 13, weight: .semibold))
            Text("Pro")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(FixFlyGradient.linear))
    }
}
