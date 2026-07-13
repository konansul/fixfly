import SwiftUI

enum LibraryMediaType: String, CaseIterable {
    // Video first, per the Library redesign.
    case video = "Video"
    case photo = "Photo"
}

struct LibraryCategory: Decodable, Identifiable, Hashable {
    let key: String
    let title: String
    let items: [RemoteCardItem]
    var id: String { key }
}

struct LibraryResponse: Decodable {
    // Flat lists power search (across every category of a type). The categorised
    // lists power the pills + grid.
    let videos: [RemoteCardItem]
    let photos: [RemoteCardItem]
    let videoCategories: [LibraryCategory]
    let photoCategories: [LibraryCategory]
}

struct LibraryView: View {
    var activateSearchOnAppear: Bool = false
    @State private var isSearchPresented: Bool = false

    @State private var selectedMediaType: LibraryMediaType = .video
    @State private var searchText: String = ""
    @State private var feedNavData: FeedNavigationData?

    @State private var videoCategories: [LibraryCategory] = []
    @State private var photoCategories: [LibraryCategory] = []
    @State private var videoItems: [RemoteCardItem] = []   // search pool
    @State private var photoItems: [RemoteCardItem] = []

    @State private var selectedVideoCat: String = ""
    @State private var selectedPhotoCat: String = ""

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
                            .padding(.bottom, 14)

                        // Category pills hide while searching (search spans all).
                        if searchText.isEmpty && !currentCategories.isEmpty {
                            categoryPills
                                .padding(.bottom, 16)
                        }

                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(displayedItems) { item in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        let index = displayedItems.firstIndex(where: { $0.id == item.id }) ?? 0
                                        feedNavData = FeedNavigationData(
                                            templates: displayedItems,
                                            sectionId: "library_\(selectedMediaType.rawValue.lowercased())_\(selectedCatKey)",
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
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
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

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(currentCategories) { cat in
                    PillToggle(title: cat.title, isSelected: cat.key == selectedCatKey) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if selectedMediaType == .video {
                            selectedVideoCat = cat.key
                        } else {
                            selectedPhotoCat = cat.key
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Derived

    private var currentCategories: [LibraryCategory] {
        selectedMediaType == .video ? videoCategories : photoCategories
    }

    private var selectedCatKey: String {
        selectedMediaType == .video ? selectedVideoCat : selectedPhotoCat
    }

    private var displayedItems: [RemoteCardItem] {
        if !searchText.isEmpty {
            let pool = selectedMediaType == .video ? videoItems : photoItems
            return pool.filter { ($0.styleId ?? "").localizedCaseInsensitiveContains(searchText) }
        }
        let cats = currentCategories
        return cats.first(where: { $0.key == selectedCatKey })?.items
            ?? cats.first?.items ?? []
    }

    private func loadLibraryData() async {
        guard let url = URL(string: ConfigAPI.baseURL + "/v1/library?seed=\(AppSession.seed)") else { return }
        var request = URLRequest(url: url)
        if let token = TokenStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(LibraryResponse.self, from: data)
            await MainActor.run {
                self.videoCategories = response.videoCategories
                self.photoCategories = response.photoCategories
                self.videoItems = response.videos
                self.photoItems = response.photos
                self.selectedVideoCat = response.videoCategories.first?.key ?? ""
                self.selectedPhotoCat = response.photoCategories.first?.key ?? ""
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}
