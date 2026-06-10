import SwiftUI

struct MyGenerationsView: View {
    @StateObject private var vm = MyGenerationsViewModel()
    @ObservedObject private var router = DeepLinkRouter.shared
    @State private var selectedItemForCompare: GenerationItemDTO?
    @State private var showSettings = false
    @State private var showCoinsSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var successfulItems: [GenerationItemDTO] {
        vm.items.filter { $0.status == "done" }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.clear.fixFlyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    if vm.isLoading && vm.items.isEmpty {
                        loadingView
                    } else if let errorText = vm.errorText, vm.items.isEmpty {
                        errorView(errorText)
                    } else {
                        if successfulItems.isEmpty && !vm.isLoading {
                            emptyView
                        } else {
                            ScrollView(showsIndicators: false) {
                                titleSection
                                
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(successfulItems) { item in
                                        Button {
                                            guard let outUrl = item.outputUrl, outUrl.count > 25 else { return }
                                            
                                            vm.markAsViewed(item.id)
                                            selectedItemForCompare = item
                                        } label: {
                                            ZStack(alignment: .topTrailing) {
                                                GenerationGridCard(
                                                    item: item,
                                                    formattedDate: vm.formattedDate(item.createdAt),
                                                    featureTitle: getDisplayTitle(for: item)
                                                )
                                                
                                                if vm.isNew(item.id) {
                                                    RecentBadge()
                                                        .padding(6)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .id(vm.refreshId)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showCoinsSheet) {
                CoinsWalletSheetView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCoinsSheet = true
                    } label: {
                        CoinsBadge()
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationDestination(item: $selectedItemForCompare) { selectedItem in
                let isVideo = selectedItem.outputUrl?.lowercased().hasSuffix(".mp4") == true ||
                              selectedItem.outputUrl?.lowercased().hasSuffix(".mov") == true
                
                if isVideo, let outStr = selectedItem.outputUrl, let videoURL = URL(string: outStr) {
                    VideoResultView(title: getDisplayTitle(for: selectedItem), videoURL: videoURL) {
                        Task { await vm.deleteGeneration(taskId: selectedItem.id) }
                    }
                    .toolbar(.hidden, for: .tabBar)
                } else {
                    ResultCompareView(
                        title: getDisplayTitle(for: selectedItem),
                        beforeURL: selectedItem.inputUrl,
                        afterURL: selectedItem.outputUrl ?? ""
                    ) {
                        Task { await vm.deleteGeneration(taskId: selectedItem.id) }
                    }
                    .toolbar(.hidden, for: .tabBar)
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                // Always refetch: a generation may have finished while the
                // user was elsewhere in the app, and nothing else refreshes
                // this list when the processing screen was closed early.
                Task {
                    await vm.load(force: true)
                }
            }
            .refreshable {
                await vm.load(force: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .generationNeedsRefresh)) { _ in
                Task {
                    await vm.load(force: true)
                }
            }
            .task(id: router.pendingGenerationTaskId) {
                guard router.pendingGenerationTaskId != nil else { return }
                await openPendingGeneration()
            }
        }
    }

    /// Opens the result for the generation a tapped push points to.
    private func openPendingGeneration() async {
        guard let taskId = router.pendingGenerationTaskId else { return }

        // The generation is likely brand-new, so refresh to be sure it's loaded.
        if vm.items.first(where: { $0.id == taskId }) == nil {
            await vm.load(force: true)
        }

        if let item = vm.items.first(where: { $0.id == taskId }),
           item.status == "done",
           let outUrl = item.outputUrl, outUrl.count > 25 {
            vm.markAsViewed(item.id)
            selectedItemForCompare = item
        }

        router.pendingGenerationTaskId = nil
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Generations")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)

            Text("All your processed images in one place. Please, save your recent generations, they expire in 14 days.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 18)
    }

    private func getDisplayTitle(for item: GenerationItemDTO) -> String {
        if item.featureKey == "nano_banana_image" || item.featureKey == "prompt_to_image" {
            if let meta = item.requestMeta, let styleValue = meta["style"] {
                switch styleValue {
                case .string(let name):
                    return name == "None" ? "Custom Photo" : formatStyleName(name)
                default:
                    return "AI Photo"
                }
            }
            return "AI Photo"
        }
        
        if item.featureKey == "prompt_to_video" {
            if let meta = item.requestMeta, let styleValue = meta["style"] {
                switch styleValue {
                case .string(let name):
                    return name == "None" ? "Custom Video" : formatStyleName(name)
                default:
                    break
                }
            }
            return "AI Video"
        }

        if item.featureKey == "template_to_video" {
            if let meta = item.requestMeta, let styleIdValue = meta["style_id"] {
                return formatStyleName(styleIdValue.description)
            }
            return "Video Template"
        }
        
        return vm.featureTitle(item.featureKey)
    }

    private func formatStyleName(_ name: String) -> String {
        if name.lowercased() == "none" { return "Custom Generation" }
        
        return name
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView().tint(.white).scaleEffect(1.1)
            Text("Loading...")
                .foregroundStyle(.white.opacity(0.8))
                .font(.system(size: 15, weight: .medium))
            Spacer()
        }
    }

    private func errorView(_ text: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 28)).foregroundStyle(.yellow)
            Text("Something went wrong").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
            Text(text).multilineTextAlignment(.center).font(.system(size: 14)).foregroundStyle(.white.opacity(0.7)).padding(.horizontal, 28)
            Button("Try Again") { Task { await vm.load(force: true) } }
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(.black).padding(.horizontal, 18).padding(.vertical, 10).background(Color.white).clipShape(Capsule())
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 30)).foregroundStyle(.white.opacity(0.8))
            Text("No generations yet").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
            Text("Your processed photos will appear here.").font(.system(size: 14)).foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
    }
}

struct RecentBadge: View {
    var body: some View {
        Text("NEW")
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
//            .background(Color("backgroundcolor"))
            .background(FixFlyGradient.linear)
//            .background(
//                LinearGradient(
//                    colors: [
//                        Color(red: 0.4, green: 0.0, blue: 0.8),
//                        Color(red: 0.1, green: 0.2, blue: 0.8)
//                    ],
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//            )
            .clipShape(Capsule())
            .shadow(radius: 2)
    }
}
