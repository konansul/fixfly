//
//  DuoCatalogView.swift
//  FixFly
//
//  "See all" grid for the duo (two-people) feature.
//

import SwiftUI

struct DuoCatalogView: View {
    @StateObject private var vm = DuoViewModel()

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            FixFlyBackground(imageName: "fixfly_bg")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                if vm.templates.isEmpty && vm.isLoading {
                    ProgressView().tint(.white).padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(vm.templates) { template in
                            NavigationLink {
                                DuoDetailView(template: template)
                                    .toolbar(.hidden, for: .tabBar)
                            } label: {
                                GridRemoteMediaCard(item: template.cardItem)
                                    .allowsHitTesting(false)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Together")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
    }
}
