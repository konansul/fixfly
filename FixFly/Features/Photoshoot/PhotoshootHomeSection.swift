//
//  PhotoshootHomeSection.swift
//  FixFly
//
//  The Home entry point for the photoshoot feature. Self-contained: it loads the
//  catalog itself and renders nothing until there's at least one template, so it
//  never affects the rest of the (server-driven) Home screen if it fails to load.
//

import SwiftUI

struct PhotoshootHomeSection: View {
    @StateObject private var vm = PhotoshootViewModel()

    var body: some View {
        // A plain VStack (not a Group) is a concrete container, so `.task` fires
        // even before any templates load. A `.task` on a Group whose body is empty
        // at first render never runs — which is why the row never appeared.
        VStack(alignment: .leading, spacing: 14) {
            if !vm.templates.isEmpty {
                header
                    .padding(.horizontal, 10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(vm.templates) { template in
                            NavigationLink {
                                PhotoshootDetailView(template: template)
                                    .toolbar(.hidden, for: .tabBar)
                            } label: {
                                PhotoshootStackedCardView(template: template)
                                    .frame(width: 150)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            })
                        }
                    }
                    .padding(.horizontal, 10)
                }
            } else if vm.isLoading {
                // Keep the row present (and the task alive) while the catalog loads.
                header
                    .padding(.horizontal, 10)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            // Transparent placeholder, not a grey box (matches the
                            // standard cards while they load).
                            MediaLoadingPlaceholder()
                                .frame(width: 150, height: 196)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
        .task { await vm.load() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 16, weight: .bold))
                    Text("AI Photoshoot")
                        .font(.system(size: 22, weight: .bold))
                }
                .foregroundStyle(.white)

                Text("Turn your selfie into 5 stunning photos")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            NavigationLink {
                PhotoshootCatalogView()
                    .toolbar(.hidden, for: .tabBar)
            } label: {
                seeAllArrow
            }
        }
    }

    @ViewBuilder
    private var seeAllArrow: some View {
        let base = Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)

        if #available(iOS 26.0, *) {
            base.glassEffect(.regular, in: Circle())
        } else {
            base.background(Color.white.opacity(0.1)).clipShape(Circle())
        }
    }
}

/// The Home card for a photoshoot: a fanned stack of "photos" so it reads as a
/// SET, not a single image. Two example frames peek out behind, tilted, with the
/// poster on top carrying the name + photo count.
struct PhotoshootStackedCardView: View {
    let template: PhotoshootTemplateDTO

    var body: some View {
        // Adaptive: sizes the fan to the available width, so the same card is
        // compact on the Home row (caller sets width 150) and larger in the
        // catalog grid (fills the cell).
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cardW = w * 0.88
            let cardH = h * 0.90

            ZStack {
                photoCard(url: backURL(2), w: cardW, h: cardH)
                    .scaleEffect(0.94)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -w * 0.055, y: h * 0.018)

                photoCard(url: backURL(1), w: cardW, h: cardH)
                    .scaleEffect(0.97)
                    .rotationEffect(.degrees(5))
                    .offset(x: w * 0.055, y: h * 0.010)

                photoCard(url: template.posterUrl, w: cardW, h: cardH, front: true)
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(150.0 / 196.0, contentMode: .fit)
    }

    /// The two back cards in the fan are tilted and mostly hidden, so they reuse the
    /// poster instead of loading separate examples — the card fetches ONE image
    /// (AsyncImage dedupes by URL), not three, which makes the row load faster.
    private func backURL(_ i: Int) -> String {
        template.posterUrl
    }

    private func photoCard(url: String, w: CGFloat, h: CGFloat, front: Bool = false) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                MediaLoadingPlaceholder()
            }
        }
        .frame(width: w, height: h)
        .background(Color.clear)
        // Bottom-left: "5 photos" (plain, no capsule) sitting just above the name.
        // No bottom scrim — a soft text shadow keeps it legible over any photo.
        .overlay(alignment: .bottomLeading) {
            if front {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(template.photoCount) photos")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                    Text(template.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)   // long names (Professional Studio) shrink to fit
                }
                .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // No white outline — a soft shadow alone separates the frames in the stack.
        .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 3)
    }
}
