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
    @State private var isSearchPresented: Bool = false

    @State private var selectedMediaType: LibraryMediaType = .photo
    @State private var searchText: String = ""
    @State private var feedNavData: FeedNavigationData?
    @State private var videoItems: [RemoteCardItem] = []
    @State private var photoItems: [RemoteCardItem] = []
    @State private var isLoading: Bool = true
    @State private var showPaywall: Bool = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.fixFlyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        mediaTypeToggle
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 24)

                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(filteredItems) { item in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        let index = filteredItems.firstIndex(where: { $0.id == item.id }) ?? 0
                                        feedNavData = FeedNavigationData(
                                            templates: filteredItems,
                                            sectionId: "library_\(selectedMediaType.rawValue.lowercased())",
                                            currentIndex: index
                                        )
                                    } label: {
                                        GridRemoteMediaCard(item: item)
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
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                prompt: "Search styles..."
            )
            .task {
                await loadLibraryData()
            }
            .onAppear {
                if activateSearchOnAppear {
                    isSearchPresented = true
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

    private var mediaTypeToggle: some View {
        Picker("Media Type", selection: $selectedMediaType) {
            ForEach(LibraryMediaType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .clipped()
        .contentShape(Rectangle())
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
