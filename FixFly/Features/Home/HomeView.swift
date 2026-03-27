import SwiftUI

struct SectionGridData: Identifiable, Hashable {
    let id = UUID()
    let sectionId: String
    let title: String
    let items: [RemoteCardItem]
    
    static func == (lhs: SectionGridData, rhs: SectionGridData) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FeedNavigationData: Identifiable, Hashable {
    let id = UUID()
    let templates: [RemoteCardItem]
    let sectionId: String
    let currentIndex: Int
    
    static func == (lhs: FeedNavigationData, rhs: FeedNavigationData) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var selectedTabBySection: [String: String] = [:]
    @State private var showPaywall = false
    
    @State private var selectedFeature: FeatureConfig?
    @State private var selectedGridData: SectionGridData?
    @State private var feedNavData: FeedNavigationData?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        HeroHeaderRemote(heroItems: vm.home?.hero.items ?? [])

                        ForEach(vm.home?.sections ?? []) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(section)
                                    .padding(.horizontal, 18)

                                switch section.type {
                                case .carousel:
                                    HorizontalRemoteCards(items: section.items ?? []) { item in
                                        onCardTap(section: section, item: item)
                                    }

                                case .carouselTabs:
                                    let tabs = section.tabs ?? []
                                    tabsRow(sectionId: section.id, tabs: tabs)
                                        .padding(.horizontal, 18)

                                    HorizontalRemoteCards(
                                        items: itemsForSelectedTab(sectionId: section.id, tabs: tabs)
                                    ) { item in
                                        onCardTap(section: section, item: item)
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 28)
                    }
                }

                if vm.isLoading {
                    loadingOverlay
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .navigationDestination(item: $selectedFeature) { cfg in
                FeatureUploadView(config: cfg)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(item: $selectedGridData) { data in
                SectionGridView(sectionId: data.sectionId, title: data.title, items: data.items)
                    // .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(item: $feedNavData) { data in
                TemplateFeedView(
                    templates: data.templates,
                    sectionId: data.sectionId,
                    currentIndex: data.currentIndex
                )
                .toolbar(.hidden, for: .tabBar)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationBar(showPaywall: $showPaywall)
            }
            .overlay(alignment: .bottom) {
                if let err = vm.errorText {
                    errorToast(err)
                }
            }
            .ignoresSafeArea()
        }
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView().tint(.white)
            Text("Loading...")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func errorToast(_ err: String) -> some View {
        Text(err)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.red.opacity(0.25))
                    .overlay(Capsule().stroke(Color.red.opacity(0.35), lineWidth: 1))
            )
            .padding(.bottom, 14)
    }

    private struct SectionTitle: View {
        let icon: String
        let title: String
        var onTitleTap: (() -> Void)? = nil
        var onSeeAllTap: (() -> Void)? = nil

        var body: some View {
            HStack(spacing: 8) {
                Button {
                    onTitleTap?()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
                .disabled(onTitleTap == nil)
                    
                Spacer()
                    
                if let onSeeAllTap = onSeeAllTap {
                    Button(action: onSeeAllTap) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func sectionHeader(_ section: HomeSectionDTO) -> some View {
        let itemsForGrid = section.type == .carouselTabs ? itemsForSelectedTab(sectionId: section.id, tabs: section.tabs ?? []) : (section.items ?? [])
        
        if let action = section.action, action.type == .navigate {
            SectionTitle(icon: section.icon, title: section.title, onTitleTap: {
                let cfg = FeatureConfig(
                    title: section.title,
                    endpointPath: endpointPath(for: section.id),
                    extraFields: [:],
                    accepts: "image/png",
                    placeholderText: "Your result will appear here",
                    processingTitle: "Processing…",
                    processingSubtitle: "This usually takes a few seconds"
                )
                selectedFeature = cfg
            }, onSeeAllTap: itemsForGrid.isEmpty ? nil : {
                selectedGridData = SectionGridData(sectionId: section.id, title: section.title, items: itemsForGrid)
            })
        } else {
            SectionTitle(icon: section.icon, title: section.title, onTitleTap: nil, onSeeAllTap: itemsForGrid.isEmpty ? nil : {
                selectedGridData = SectionGridData(sectionId: section.id, title: section.title, items: itemsForGrid)
            })
        }
    }

    private func tabsRow(sectionId: String, tabs: [HomeTabDTO]) -> some View {
        HStack(spacing: 10) {
            ForEach(tabs) { tab in
                PillToggle(
                    title: tab.title,
                    isSelected: currentTabId(sectionId: sectionId, tabs: tabs) == tab.id
                ) {
                    selectedTabBySection[sectionId] = tab.id
                }
            }
            Spacer()
        }
    }

    private func currentTabId(sectionId: String, tabs: [HomeTabDTO]) -> String? {
        if let selected = selectedTabBySection[sectionId] { return selected }
        return tabs.first?.id
    }

    private func itemsForSelectedTab(sectionId: String, tabs: [HomeTabDTO]) -> [RemoteCardItem] {
        guard let tabId = currentTabId(sectionId: sectionId, tabs: tabs) else { return [] }
        return tabs.first(where: { $0.id == tabId })?.items ?? []
    }

    private func onCardTap(section: HomeSectionDTO, item: RemoteCardItem) {
        let allItemsInSection: [RemoteCardItem]
        if section.type == .carouselTabs {
            allItemsInSection = itemsForSelectedTab(sectionId: section.id, tabs: section.tabs ?? [])
        } else {
            allItemsInSection = section.items ?? []
        }
        
        let clickedIndex = allItemsInSection.firstIndex(where: { $0.id == item.id }) ?? 0
        
        feedNavData = FeedNavigationData(
            templates: allItemsInSection,
            sectionId: section.id,
            currentIndex: clickedIndex
        )
    }

    private func endpointPath(for sectionId: String) -> String {
        switch sectionId {
        case "anime": return "/v1/anime-avatar"
        case "enhance": return "/v1/enhance-photo"
        case "restore": return "/v1/restore-old-photo"
        default: return "/v1/anime-avatar"
        }
    }
}

struct SectionGridView: View {
    let sectionId: String
    let title: String
    let items: [RemoteCardItem]
    
    @Environment(\.dismiss) private var dismiss
    @State private var feedNavData: FeedNavigationData?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { item in
                        Button {
                            let clickedIndex = items.firstIndex(where: { $0.id == item.id }) ?? 0
                            feedNavData = FeedNavigationData(
                                templates: items,
                                sectionId: sectionId,
                                currentIndex: clickedIndex
                            )
                        } label: {
                            GridRemoteMediaCard(item: item)
                                .allowsHitTesting(false)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
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

struct GridRemoteMediaCard: View {
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
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .overlay(alignment: .bottomLeading) {
            if let styleName = item.styleId {
                Text(styleName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(10)
            }
        }
    }
}
