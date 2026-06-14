import SwiftUI
import PhotosUI

struct GeneratePhotoFormView: View {
    @State private var prompt: String = ""
    @State private var selectedStyle: String = "None"
    @State private var selectedAspectRatio: String = "9:16"
    @State private var isGenerating: Bool = false
    @State private var showCoinsSheet = false
    
    @State private var selectedImages: [UIImage] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    
    @State private var showRealPhotoPicker = false
    
    @State private var toastMessage: String?
    
    @FocusState private var isPromptFocused: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var processingTaskId: String?
    @State private var finalResultImageUrl: String?
    @State private var showResult = false
    
    let styles = ["None", "Cinematic", "Anime", "Cyberpunk", "3D Render", "Digital Art", "Oil Painting", "Watercolor", "Pixel Art", "Fantasy", "Photorealistic", "Vintage", "Comic", "Pop Art", "Neon", "Sketch"]
    let aspectRatios = ["1:1", "9:16", "16:9", "3:4", "4:3"]
    
    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        promptSection
                        aspectRatioSection
                        multiplePhotoSection
                        styleSection
                    }
                    .padding(.vertical, 20)
                }
                
                generateButton
            }
            
            if isGenerating {
                processingOverlay
            }
            
            if let toast = toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.green.opacity(0.8)))
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .onTapGesture {
            isPromptFocused = false
        }
        .onAppear {
            AppAnalytics.track(.featureSelected(kind: "photo"))
        }
        .onChange(of: photoPickerItems) { oldValue, newItems in
            Task {
                selectedImages.removeAll()
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Create Photo  ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCoinsSheet = true
                } label: {
                    CoinsBadge()
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showCoinsSheet) {
                    CoinsWalletSheetView()
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .sheet(item: $processingTaskId) { taskId in
            PhotoProcessingView(taskId: taskId, onComplete: { outputUrl in
                self.processingTaskId = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NotificationCenter.default.post(name: .generationNeedsRefresh, object: nil)
                    self.finalResultImageUrl = outputUrl
                    self.showResult = true
                }
            })
            .presentationDragIndicator(.visible)
        }
        // Удалили блок .sheet(isPresented: $showGuidelinesSheet)
        .photosPicker(
            isPresented: $showRealPhotoPicker,
            selection: $photoPickerItems,
            maxSelectionCount: 3,
            matching: .images
        )
        .navigationDestination(isPresented: $showResult) {
            if let afterUrl = finalResultImageUrl {
                if let firstImage = selectedImages.first {
                    ResultCompareView(
                        title: "Generated Photo",
                        before: firstImage,
                        afterURL: afterUrl
                    )
                    .toolbar(.hidden, for: .tabBar)
                } else {
                    ResultCompareView(
                        title: "Generated Photo",
                        before: UIImage(),
                        afterURL: afterUrl
                    )
                    .toolbar(.hidden, for: .tabBar)
                }
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What do you want to see?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isPromptFocused ? FixFlyGradient.accent : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                
                if prompt.isEmpty {
                    Text("Describe your idea in detail...")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $prompt)
                    .focused($isPromptFocused)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .frame(height: 140)
        }
        .padding(.horizontal, 16)
    }
    
    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aspect Ratio")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(aspectRatios, id: \.self) { ratio in
                        let isSelected = selectedAspectRatio == ratio
                        Button {
                            selectedAspectRatio = ratio
                        } label: {
                            HStack(spacing: 7) {
                                aspectRatioIcon(for: ratio, isSelected: isSelected)
                                Text(ratio)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isSelected ? FixFlyGradient.accent : Color.white.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    /// Маленький контур-прямоугольник в пропорциях соотношения (1:1 — квадрат,
    /// 9:16 — вертикальный, 16:9 — горизонтальный и т.д.). Размеры считаются из
    /// самих чисел "w:h", поэтому работает для любого соотношения. Контейнер
    /// фиксирован 18×18, чтобы капсулы выравнивались по высоте.
    private func aspectRatioIcon(for ratio: String, isSelected: Bool) -> some View {
        let comps = ratio.split(separator: ":").compactMap { Double($0) }
        let aw = comps.count == 2 ? comps[0] : 1
        let ah = comps.count == 2 ? comps[1] : 1
        let maxSide: CGFloat = 16
        let scale = maxSide / CGFloat(max(aw, ah))

        return Rectangle()
            .stroke(isSelected ? Color.white : Color.white.opacity(0.7), lineWidth: 1.8)
            .frame(width: CGFloat(aw) * scale, height: CGFloat(ah) * scale)
            .frame(width: 18, height: 18)
    }

    private var multiplePhotoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reference Photos")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                
                if !selectedImages.isEmpty {
                    Button {
                        // Сразу открываем галерею
                        showRealPhotoPicker = true
                    } label: {
                        Text("Edit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(FixFlyGradient.accent)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedImages.remove(at: index)
                                        photoPickerItems.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white, Color.black.opacity(0.7))
                                        .background(Circle().fill(Color.black))
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            } else {
                Button {
                    // Сразу открываем галерею
                    showRealPhotoPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 18))
                        Text("Add Reference Photos")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(styles, id: \.self) { style in
                        Button {
                            selectedStyle = style
                        } label: {
                            Text(style)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(selectedStyle == style ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedStyle == style ? FixFlyGradient.accent : Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var generateButton: some View {
        Button {
            startGeneration()
        } label: {
            HStack {
                Text("Generate Image")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "bitcoinsign.circle.fill")
                    Text("150")
                }
                .font(.system(size: 15, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
            }
            .foregroundStyle(.white)
            .padding(.leading, 24)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(FixFlyGradient.linear)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: FixFlyGradient.purple.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
        .opacity(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 10)
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().tint(.white).scaleEffect(1.5)
                Text("Sending request...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
    
    private func startGeneration() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AppAnalytics.track(.generateStarted(kind: "photo", template: nil))
        isPromptFocused = false
        isGenerating = true
        
        let fields = [
            "prompt": prompt,
            "style": selectedStyle,
            "aspect_ratio": selectedAspectRatio
        ]
        
        Task {
            do {
                let generatedTaskId = try await MultipartAPI.shared.startBackgroundGeneration(
                    endpointPath: "/v1/generate-nano-banana",
                    images: selectedImages,
                    extraFields: fields
                )
                
                await WalletManager.shared.refreshBalance()
                
                await MainActor.run {
                    isGenerating = false
                    processingTaskId = generatedTaskId
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    showToast("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showToast(_ message: String) {
        withAnimation(.easeInOut(duration: 0.3)) { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.3)) { toastMessage = nil }
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
