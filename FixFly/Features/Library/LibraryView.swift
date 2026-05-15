import SwiftUI

enum LibraryMediaType: String, CaseIterable {
    case photo = "Photo"
    case video = "Video"
}

struct LibraryResponse: Decodable {
    let videos: [RemoteCardItem]
    let photos: [RemoteCardItem]
}

struct LibraryView: View {
    var activateSearchOnAppear: Bool = false
    @FocusState private var isSearchFocused: Bool
    
    @State private var selectedMediaType: LibraryMediaType = .photo
    @State private var searchText: String = ""
    @State private var feedNavData: FeedNavigationData?
    @State private var videoItems: [RemoteCardItem] = []
    @State private var photoItems: [RemoteCardItem] = []
    @State private var isLoading: Bool = true
    @State private var showPaywall: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.fixFlyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        searchBar
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 16)

                        mediaTypeToggle
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)

                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 40)
                        } else {
                            HStack(alignment: .top, spacing: 16) {
                                LazyVStack(spacing: 16) {
                                    ForEach(leftColumnItems, id: \.1.id) { index, item in
                                        cardButton(for: item, index: index)
                                    }
                                }
                                
                                LazyVStack(spacing: 16) {
                                    ForEach(rightColumnItems, id: \.1.id) { index, item in
                                        cardButton(for: item, index: index)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationBar(showPaywall: $showPaywall)
            }
            .task {
                await loadLibraryData()
            }
            .onAppear {
                if activateSearchOnAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFocused = true
                    }
                }
            }
            .navigationDestination(item: $feedNavData) { data in
                TemplateFeedView(
                    templates: data.templates,
                    sectionId: data.sectionId,
                    currentIndex: data.currentIndex
                )
                .toolbar(.hidden, for: .tabBar)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            TextField("Search styles...", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    isSearchFocused = false
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var mediaTypeToggle: some View {
        Picker("Media Type", selection: $selectedMediaType) {
            ForEach(LibraryMediaType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .clipped()
        .contentShape(Rectangle())
        .onChange(of: selectedMediaType) { _ in
            isSearchFocused = false
        }
    }

    private var filteredItems: [RemoteCardItem] {
        let items = selectedMediaType == .video ? videoItems : photoItems
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                (item.styleId ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var leftColumnItems: [(Int, RemoteCardItem)] {
        filteredItems.enumerated().filter { $0.offset % 2 == 0 }.map { ($0.offset, $0.element) }
    }

    private var rightColumnItems: [(Int, RemoteCardItem)] {
        filteredItems.enumerated().filter { $0.offset % 2 != 0 }.map { ($0.offset, $0.element) }
    }

    private func cardButton(for item: RemoteCardItem, index: Int) -> some View {
        let heights: [CGFloat] = [220, 280, 250, 300, 240, 260, 290, 230]
        let cardHeight = heights[index % heights.count]

        return Button {
            let clickedIndex = filteredItems.firstIndex(where: { $0.id == item.id }) ?? 0
            feedNavData = FeedNavigationData(
                templates: filteredItems,
                sectionId: "library_\(selectedMediaType.rawValue.lowercased())",
                currentIndex: clickedIndex
            )
        } label: {
            ZStack(alignment: .bottomLeading) {
                LibraryGridRemoteMediaCard(item: item)
                    .frame(height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                Text(item.styleId ?? "Unknown")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(12)
            }
            .frame(height: cardHeight)
            .allowsHitTesting(false)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func loadLibraryData() async {
        guard let url = URL(string: ConfigAPI.baseURL + "/v1/library") else { return }
        var request = URLRequest(url: url)
        if let token = TokenStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(LibraryResponse.self, from: data)
            await MainActor.run {
                self.videoItems = response.videos
                self.photoItems = response.photos
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}

struct LibraryGridRemoteMediaCard: View {
    let item: RemoteCardItem
    var body: some View {
        ZStack {
            Color.white.opacity(0.05)
            if let url = URL(string: item.mediaUrl) {
                if item.mediaType == .video || item.mediaUrl.hasSuffix(".mp4") {
                    LoopingCardVideoView(url: url)
                } else {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            ProgressView().tint(.white)
                        }
                    }
                }
            }
        }
        .aspectRatio(3/4, contentMode: .fill)
        .frame(minWidth: 0, maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
