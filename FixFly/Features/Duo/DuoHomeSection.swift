//
//  DuoHomeSection.swift
//  FixFly
//
//  The Home entry point for the duo (two-people) feature. Self-contained: it loads
//  its own catalog and renders nothing until there's at least one template, so it
//  never affects the rest of the Home screen if it fails to load.
//

import SwiftUI

struct DuoHomeSection: View {
    @StateObject private var vm = DuoViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !vm.templates.isEmpty {
                header
                    .padding(.horizontal, 10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(vm.templates) { template in
                            NavigationLink {
                                DuoDetailView(template: template)
                                    .toolbar(.hidden, for: .tabBar)
                            } label: {
                                // Disable hit-testing on the card so the video view
                                // doesn't eat the tap; contentShape makes the whole
                                // card area the tap target (matches HorizontalRemoteCards).
                                RoundedRemoteMediaCard(item: template.cardItem)
                                    .allowsHitTesting(false)
                                    .contentShape(Rectangle())
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
                header
                    .padding(.horizontal, 10)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            // Transparent placeholder (Color.clear) + faint outline —
                            // matches a loading standard card, not a grey box.
                            MediaLoadingPlaceholder()
                                .frame(width: 144, height: 192)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
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
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Together")
                        .font(.system(size: 22, weight: .bold))
                }
                .foregroundStyle(.white)

                Text("A warm hug with someone you love")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            NavigationLink {
                DuoCatalogView()
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
