//
//  CoinsWalletSheetView.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//

import SwiftUI

struct CoinsWalletSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = WalletSheetStore()

    @State private var coinRotation: Double = 0

    var body: some View {
        ZStack {
            FixFlyBackground(imageName: "fixfly_bg")

            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        balanceHero

                        if let errorText = store.errorText {
                            errorCard(errorText)
                        }

                        if store.isLoading && store.items.isEmpty {
                            loadingBlock
                        } else if !store.isLoading && store.items.isEmpty {
                            emptyBlock
                        } else {
                            ledgerSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
                .refreshable {
                    Task { await store.load() }
                }
            }
        }
        .task {
            startCoinAnimation()
            await store.load()
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Coins")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                Task { await store.load() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var balanceHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.18))
                    .frame(width: 108, height: 108)
                    .blur(radius: 10)

                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 82))
                    .foregroundStyle(.yellow)
                    .rotation3DEffect(.degrees(coinRotation), axis: (x: 0, y: 1, z: 0))
            }

            Text("\(store.balance)")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)

            Text("Available coins")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

            HStack(spacing: 10) {
                infoChip(title: "Status", value: "Active")
                infoChip(title: "Transactions", value: "\(store.items.count)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transactions")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                ForEach(store.items) { item in
                    LedgerRowView(
                        item: item,
                        formattedDate: store.formattedDate(item.createdAt),
                        title: store.reasonTitle(item.reason),
                        subtitle: store.ledgerSubtitle(item)
                    )
                }
            }
        }
    }

    private var loadingBlock: some View {
        VStack(spacing: 12) {
            ProgressView().tint(.white)
            Text("Loading transactions...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var emptyBlock: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.7))

            Text("No transactions yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("Your coin history will appear here.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func errorCard(_ text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.yellow)

            Text("Could not load wallet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await store.load() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func infoChip(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }

    private func startCoinAnimation() {
        coinRotation = 0
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
            coinRotation = 360
        }
    }
}
