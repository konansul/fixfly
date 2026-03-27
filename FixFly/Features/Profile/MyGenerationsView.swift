import SwiftUI

struct MyGenerationsView: View {
    @StateObject private var vm = MyGenerationsViewModel()
    @State private var selectedItemForCompare: GenerationItemDTO?
    @State private var showSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.clear.fixFlyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    titleSection

                    if vm.isLoading && vm.items.isEmpty {
                        loadingView
                    } else if let errorText = vm.errorText, vm.items.isEmpty {
                        errorView(errorText)
                    } else {
                        let successfulItems = vm.items.filter { $0.status == "done" }
                        
                        if successfulItems.isEmpty && !vm.isLoading {
                            emptyView
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(successfulItems) { item in
                                        Button {
                                            guard let outUrl = item.outputUrl, outUrl.count > 25 else {
                                                return
                                            }
                                            selectedItemForCompare = item
                                        } label: {
                                            GenerationGridCard(
                                                item: item,
                                                formattedDate: vm.formattedDate(item.createdAt),
                                                featureTitle: getDisplayTitle(for: item)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                            }
                        }
                    }
                }
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
                    CoinsBadge()
                }
            }
            .navigationDestination(item: $selectedItemForCompare) { selectedItem in
                let isVideo = selectedItem.outputUrl?.lowercased().hasSuffix(".mp4") == true ||
                              selectedItem.outputUrl?.lowercased().hasSuffix(".mov") == true
                
                if isVideo, let outStr = selectedItem.outputUrl, let videoURL = URL(string: outStr) {
                    VideoResultView(videoURL: videoURL)
                        .toolbar(.hidden, for: .tabBar)
                } else {
                    ResultCompareView(
                        beforeURL: selectedItem.inputUrl,
                        afterURL: selectedItem.outputUrl ?? ""
                    )
                    .toolbar(.hidden, for: .tabBar)
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                Task {
                    await vm.load(force: true)
                }
            }
            .refreshable {
                await vm.load(force: true)
            }
        }
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
        if item.featureKey == "template_to_video" {
            if let meta = item.requestMeta as? [String: StringOrIntOrDoubleOrBool],
               let styleId = meta["style_id"]?.description {
                return styleId.capitalized
            }
            return "Video Template"
        }
        if item.featureKey == "prompt_to_video" { return "Custom Video" }
        if item.featureKey == "prompt_to_image" { return "Custom Image" }
        return vm.featureTitle(item.featureKey)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView().tint(.white).scaleEffect(1.1)
            Text("Loading your generations...")
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
