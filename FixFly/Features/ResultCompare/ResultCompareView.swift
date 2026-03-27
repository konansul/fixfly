import SwiftUI

struct ResultCompareView: View {
    let beforeSource: MediaSource?
    let afterSource: MediaSource

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ResultCompareViewModel()

    @State private var sliderX: CGFloat = 0.5
    @State private var showShare = false
    @State private var isCompareMode = false
    @State private var zoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0

    init(before: UIImage, after: UIImage) {
        self.beforeSource = .image(before)
        self.afterSource = .image(after)
    }

    init(beforeURL: String?, afterURL: String) {
        if let beforeURL, !beforeURL.isEmpty {
            self.beforeSource = .remote(beforeURL)
        } else {
            self.beforeSource = nil
        }
        self.afterSource = .remote(afterURL)
    }

    var body: some View {
        ZStack {
            FixFlyBackground(imageName: "fixfly_bg")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 14)

                    if isCompareMode, beforeSource != nil {
                        compareBlock
                            .padding(.horizontal, 16)
                    } else {
                        resultBlock
                            .padding(.horizontal, 16)
                    }

                    actionButtons
                        .padding(.horizontal, 16)
                        .padding(.top, 18)

                    shareSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    Spacer(minLength: 24)
                }
                .padding(.bottom, 24)
            }

            if let toast = viewModel.toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .padding(.bottom, 24)
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: viewModel.shareItems(for: afterSource))
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            sliderX = 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { sliderX = 0.5 }
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
//            ToolbarItem(placement: .topBarLeading) {
//                Button {
//                    dismiss()
//                } label: {
//                    Image(systemName: "chevron.left")
//                        .font(.system(size: 16, weight: .semibold))
//                        .foregroundStyle(.white.opacity(0.95))
//                        .frame(width: 34, height: 34)
//                        .background(Color.white.opacity(0.06))
//                        .clipShape(Circle())
//                }
//            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await viewModel.saveResult(from: afterSource) }
                    } label: { Label("Save to Photos", systemImage: "square.and.arrow.down") }

                    Button { showShare = true } label: {
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
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
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

    private var resultBlock: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topTrailing) {
                ZoomableSourceImageView(source: afterSource, zoom: $zoom, lastZoom: $lastZoom)
                    .frame(width: w, height: 420)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .frame(width: w, height: 420)
            .position(x: w / 2, y: 210)
        }
        .frame(height: 420)
    }

    private var compareBlock: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 420
            let x = max(0, min(1, sliderX)) * w
            let handleSize: CGFloat = 34
            let bottomInset: CGFloat = 22
            let handleY = h - bottomInset - handleSize / 2

            ZStack {
                SourceImageView(source: afterSource)
                    .frame(width: w, height: h)
                    .background(Color.black)

                if let beforeSource {
                    SourceImageView(source: beforeSource)
                        .frame(width: w, height: h)
                        .background(Color.black)
                        .mask(
                            Rectangle()
                                .frame(width: x, height: h)
                                .offset(x: -(w - x) / 2)
                        )
                }

                HStack {
                    chip("Before")
                    Spacer()
                    chip("After")
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .frame(width: w, height: h, alignment: .top)

                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 2, height: h)
                    .position(x: x, y: h / 2)

                handle
                    .position(x: x, y: handleY)
            }
            .frame(width: w, height: h)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newX = max(0, min(w, value.location.x))
                        sliderX = newX / w
                    }
            )
            .position(x: w / 2, y: h / 2)
        }
        .frame(height: 420)
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
                        .frame(height: 56)
                        .background(Color.white.opacity(0.08)) // Прозрачная кнопка
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(accentGradient, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button { showShare = true } label: {
                Text("Share")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accentGradient) // Цветная кнопка с градиентом
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var shareSection: some View {
        VStack(spacing: 16) {
            Text("Share to")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))

            HStack(spacing: 22) {
                shareButton(icon: "arrow.down", title: "Download") {
                    Task { await viewModel.saveResult(from: afterSource) }
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
}
