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
    
    @State private var selectedGridData: SectionGridData?
    @State private var feedNavData: FeedNavigationData?

    var body: some View {
        NavigationStack {
            ZStack {
//                Color.clear.fixFlyBackground()
//                    .ignoresSafeArea()
//                    .allowsHitTesting(false)
//                    .zIndex(0)


                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        HeroHeaderRemote(heroItems: vm.home?.hero.items ?? []) { tappedItem in
                            handleHeroTap(tappedItem)
                        }

                        ForEach(vm.home?.sections ?? []) { section in
                            VStack(alignment: .leading, spacing: 14) {
                                sectionHeader(section)
                                    .padding(.horizontal, 10)

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
                        Spacer(minLength: 40)
                    }
                }
                .zIndex(1)

                if vm.isLoading && vm.home == nil {
                    ProgressView().tint(.white).zIndex(2)
                }
            }
            .ignoresSafeArea()
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .navigationDestination(item: $selectedGridData) { data in
                SectionGridView(sectionId: data.sectionId, title: data.title, items: data.items)
            }
            .navigationDestination(item: $feedNavData) { data in
                TemplateFeedView(
                    templates: data.templates,
                    sectionId: data.sectionId,
                    currentIndex: data.currentIndex
                )
                .toolbar(.hidden, for: .tabBar)
            }
            .toolbar {
                NavigationBar(showPaywall: $showPaywall)
            }
        }
    }

    private func handleHeroTap(_ item: HeroMediaItemDTO) {
        guard let targetId = item.action?.targetId else { return }
        
        var foundTemplate: RemoteCardItem?
        var foundSectionId: String?
        
        if let sections = vm.home?.sections {
            for section in sections {
                let items = (section.items ?? []) + (section.tabs?.flatMap { $0.items } ?? [])
                if let template = items.first(where: { $0.id == targetId }) {
                    foundTemplate = template
                    foundSectionId = section.id
                    break
                }
            }
        }
        
        if let template = foundTemplate, let sectionId = foundSectionId {
            feedNavData = FeedNavigationData(
                templates: [template],
                sectionId: sectionId,
                currentIndex: 0
            )
        }
    }

    @ViewBuilder
    private func sectionHeader(_ section: HomeSectionDTO) -> some View {
        let itemsForGrid = section.type == .carouselTabs ? itemsForSelectedTab(sectionId: section.id, tabs: section.tabs ?? []) : (section.items ?? [])
        
        HStack(alignment: .top) { 
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: section.icon)
                        .font(.system(size: 16, weight: .bold))
                    Text(section.title)
                        .font(.system(size: 22, weight: .bold))
                }
                .foregroundStyle(.white)
                
                if let subtitle = section.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            if !itemsForGrid.isEmpty {
                Button {
                    selectedGridData = SectionGridData(sectionId: section.id, title: section.title, items: itemsForGrid)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
    }

    private func tabsRow(sectionId: String, tabs: [HomeTabDTO]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tabs) { tab in
                    PillToggle(
                        title: tab.title,
                        isSelected: currentTabId(sectionId: sectionId, tabs: tabs) == tab.id
                    ) {
                        selectedTabBySection[sectionId] = tab.id
                    }
                }
            }
        }
    }

    private func currentTabId(sectionId: String, tabs: [HomeTabDTO]) -> String? {
        selectedTabBySection[sectionId] ?? tabs.first?.id
    }

    private func itemsForSelectedTab(sectionId: String, tabs: [HomeTabDTO]) -> [RemoteCardItem] {
        guard let tabId = currentTabId(sectionId: sectionId, tabs: tabs) else { return [] }
        return tabs.first(where: { $0.id == tabId })?.items ?? []
    }

    private func onCardTap(section: HomeSectionDTO, item: RemoteCardItem) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let allItems = section.type == .carouselTabs ? itemsForSelectedTab(sectionId: section.id, tabs: section.tabs ?? []) : (section.items ?? [])
        let index = allItems.firstIndex(where: { $0.id == item.id }) ?? 0
        
        feedNavData = FeedNavigationData(
            templates: allItems,
            sectionId: section.id,
            currentIndex: index
        )
    }
}

struct SectionGridView: View {
    let sectionId: String
    let title: String
    let items: [RemoteCardItem]
    
    @Environment(\.dismiss) private var dismiss
    @State private var feedNavData: FeedNavigationData?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(items) { item in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            let index = items.firstIndex(where: { $0.id == item.id }) ?? 0
                            feedNavData = FeedNavigationData(templates: items, sectionId: sectionId, currentIndex: index)
                        } label: {
                            GridRemoteMediaCard(item: item)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                }
            }
        }
        .navigationDestination(item: $feedNavData) { data in
            TemplateFeedView(templates: data.templates, sectionId: data.sectionId, currentIndex: data.currentIndex)
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
                if item.mediaType == .video || item.mediaUrl.lowercased().hasSuffix(".mp4") {
                    LoopingCardVideoView(url: url)
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                } else {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.white.opacity(0.1)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                }
            }
        }
        .aspectRatio(3/4, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .overlay(alignment: .bottomLeading) {
            if let styleName = item.styleId, styleName.lowercased() != "none" {
                Text(styleName.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
    }
}
