import SwiftUI

struct ResultCompareView: View {
    let beforeSource: MediaSource?
    let afterSource: MediaSource
    let title: String
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ResultCompareViewModel()

    @State private var sliderX: CGFloat = 0.5
    @State private var showShare = false
    @State private var isCompareMode = false
    @State private var zoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    @State private var uiImageToShare: UIImage?
    
    @State private var showSuccessCheck = false

    init(title: String, before: UIImage, after: UIImage, onDelete: (() -> Void)? = nil) {
        self.title = title
        self.beforeSource = .image(before)
        self.afterSource = .image(after)
        self.onDelete = onDelete
    }

    init(title: String, beforeURL: String?, afterURL: String, onDelete: (() -> Void)? = nil) {
        self.title = title
        if let beforeURL, !beforeURL.isEmpty {
            self.beforeSource = .remote(beforeURL)
        } else {
            self.beforeSource = nil
        }
        self.afterSource = .remote(afterURL)
        self.onDelete = onDelete
    }

    init(title: String, before: UIImage, afterURL: String, onDelete: (() -> Void)? = nil) {
        self.title = title
        self.beforeSource = .image(before)
        self.afterSource = .remote(afterURL)
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack {
            FixFlyBackground(imageName: "fixfly_bg")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if isCompareMode, beforeSource != nil {
                        compareBlock
                            .padding(.horizontal, 16)
                    } else {
                        resultBlock
                            .padding(.horizontal, 16)
                    }

                    actionButtons
                        .padding(.horizontal, 16)

                    ShareResultSection(
                        onDownloadTap: {
                            Task { await viewModel.saveResult(from: afterSource) }
                        },
                        onShareTap: { platform in
                            prepareAndShare()
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

            if let toast = viewModel.toast, !showSuccessCheck, toast != "SUCCESS_ACTION" {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        if toast.contains("Downloading") {
                            ProgressView().tint(.white)
                        }
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
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: viewModel.toast) { oldValue, newValue in
            if newValue == "SUCCESS_ACTION" {
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
            if let image = uiImageToShare {
                ActivityView(activityItems: [image])
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            sliderX = 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { sliderX = 0.5 }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await viewModel.saveResult(from: afterSource) }
                    } label: { Label("Save to Photos", systemImage: "square.and.arrow.down") }

                    Button { prepareAndShare() } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    if beforeSource != nil {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isCompareMode.toggle()
                                resetZoom()
                            }
                        } label: {
                            Label(isCompareMode ? "Hide Compare" : "Compare", systemImage: "slider.horizontal.3")
                        }
                    }
                    
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
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

    private var accentGradient: LinearGradient {
        FixFlyGradient.linear
    }

    private var resultBlock: some View {
        ZoomableSourceImageView(source: afterSource, zoom: $zoom, lastZoom: $lastZoom)
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private var compareBlock: some View {
        SourceImageView(source: afterSource)
            .aspectRatio(contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let x = max(0, min(1, sliderX)) * w
                    let handleSize: CGFloat = 34
                    let bottomInset: CGFloat = 22
                    let handleY = h - bottomInset - handleSize / 2

                    ZStack(alignment: .topLeading) {
                        if let beforeSource {
                            SourceImageView(source: beforeSource)
                                .frame(width: w, height: h)
                                .mask(
                                    Rectangle()
                                        .frame(width: x, height: h)
                                        .position(x: x / 2, y: h / 2)
                                )
                        }

                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 2, height: h)
                            .position(x: x, y: h / 2)

                        handle
                            .position(x: x, y: handleY)

                        HStack {
                            chip("Before")
                            Spacer()
                            chip("After")
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .frame(width: w, height: h, alignment: .top)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newX = max(0, min(w, value.location.x))
                                sliderX = newX / w
                            }
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if beforeSource != nil {
                Button {
                    resetZoom()
                    withAnimation(.easeInOut(duration: 0.2)) { isCompareMode.toggle() }
                } label: {
                    Text(isCompareMode ? "Hide Compare" : "Compare")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(accentGradient, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button { prepareAndShare() } label: {
                Text("Share")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.45)))
    }

    private var handle: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 34, height: 34)
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black.opacity(0.85))
        }
        .shadow(radius: 6)
    }

    private func resetZoom() {
        zoom = 1.0
        lastZoom = 1.0
    }

    private func prepareAndShare() {
        Task {
            let urlString: String
            switch afterSource {
            case .remote(let url): urlString = url
            default: return
            }
            
            guard let url = URL(string: urlString) else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.uiImageToShare = image
                        self.showShare = true
                    }
                }
            } catch {
                print("Error loading image for share: \(error)")
            }
        }
    }
}
