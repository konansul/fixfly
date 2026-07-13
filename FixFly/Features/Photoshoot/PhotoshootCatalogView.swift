//
//  PhotoshootCatalogView.swift
//  FixFly
//
//  Grid of every photoshoot template. Pushed from the Home "AI Photoshoot" row's
//  "see all", or usable standalone.
//

import SwiftUI

struct PhotoshootCatalogView: View {
    @StateObject private var vm = PhotoshootViewModel()

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if vm.isLoading && vm.templates.isEmpty {
                ProgressView().tint(.white)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    // Same fanned stacked cards as Home, so it reads as sets of
                    // photos, not single images.
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(vm.templates) { template in
                            NavigationLink {
                                PhotoshootDetailView(template: template)
                                    .toolbar(.hidden, for: .tabBar)
                            } label: {
                                PhotoshootStackedCardView(template: template)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("AI Photoshoot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
        .refreshable { await vm.load(force: true) }
    }
}

/// The card: a template's best example, its name, and a "N photos · cost" chip.
/// No upload slot — the example image is the whole pitch.
struct PhotoshootCardView: View {
    let template: PhotoshootTemplateDTO

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: template.posterUrl)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    MediaLoadingPlaceholder()
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.75)],
                           startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                Text(template.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(template.photoCount) photos")
                    Text("·")
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.yellow)
                    Text("\(template.cost)")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(12)
        }
        .aspectRatio(3/4, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
