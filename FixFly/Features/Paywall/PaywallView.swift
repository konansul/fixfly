//
//  PaywallView.swift
//  FixFly
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PaywallViewModel()

    var body: some View {
        ZStack {
            LocalLoopingVideoView(videoName: "paywall_bg", fileExtension: "mp4")
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.70),
                    Color.black.opacity(0.95),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                Spacer()

                content
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
            }
        }
        .task { await vm.loadProducts() }
        .alert(
            "Purchase failed",
            isPresented: Binding(
                get: { vm.errorText != nil },
                set: { _ in vm.errorText = nil }
            )
        ) {
            Button("OK", role: .cancel) { vm.errorText = nil }
        } message: {
            Text(vm.errorText ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                Task { await vm.restore() }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.90))
                    .underline()
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose your Plan")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            Text("Unlock the full power of FixFly subscriptions or one-time coin packs.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            modeSwitcher
                .padding(.top, 4)

            ZStack {
                if vm.selectedProductId.contains("sub") {
                    subscriptionSection
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
                } else {
                    coinSection
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.selectedProductId.contains("sub"))

            Button {
                Task {
                    let success = await vm.purchaseSelected()
                    if success { dismiss() }
                }
            } label: {
                ZStack {
                    if vm.isPurchasing {
                        ProgressView().tint(.black)
                    } else {
                        Text(vm.primaryButtonTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(vm.isPurchasing)
            .padding(.top, 8)

            Text("Payment will be charged to your Apple ID account. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.top, 6)
                .padding(.bottom, 20)
        }
    }

    private var modeSwitcher: some View {
        let isSub = vm.selectedProductId.contains("sub")
        return ZStack(alignment: isSub ? .leading : .trailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.16))
                .frame(width: 160)
                .padding(4)
                .animation(.spring(response: 0.32, dampingFraction: 0.85), value: isSub)

            HStack(spacing: 0) {
                Button {
                    vm.selectedProductId = PaywallItemType.weeklySub.rawValue
                } label: {
                    Text("Subscription").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 52)
                }.buttonStyle(.plain)
                
                Button {
                    vm.selectedProductId = PaywallItemType.coins1200.rawValue
                } label: {
                    Text("Coins").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 52)
                }.buttonStyle(.plain)
            }
        }
        .frame(height: 52)
    }

    private var subscriptionSection: some View {
        VStack(spacing: 12) {
            PlanRow(
                title: "Weekly",
                subtitle: "2,400 Coins",
                badge: "Popular",
                rightTop: "per week",
                rightBottom: "$6.99",
                isSelected: vm.selectedProductId == PaywallItemType.weeklySub.rawValue
            ) {
                vm.selectedProductId = PaywallItemType.weeklySub.rawValue
            }

            PlanRow(
                title: "Monthly",
                subtitle: "7,200 Coins",
                badge: "Best Value",
                rightTop: "per month",
                rightBottom: "$16.99",
                isSelected: vm.selectedProductId == PaywallItemType.monthlySub.rawValue
            ) {
                vm.selectedProductId = PaywallItemType.monthlySub.rawValue
            }
        }
        .padding(.top, 6)
    }

    private var coinSection: some View {
        VStack(spacing: 12) {
            CoinRow(
                title: "Starter Pack",
                subtitle: "1,200 Coins",
                badge: nil,
                rightBottom: "$4.99",
                isSelected: vm.selectedProductId == PaywallItemType.coins1200.rawValue
            ) {
                vm.selectedProductId = PaywallItemType.coins1200.rawValue
            }

            CoinRow(
                title: "Pro Pack",
                subtitle: "3,000 Coins",
                badge: "Best Seller",
                rightBottom: "$9.99",
                isSelected: vm.selectedProductId == PaywallItemType.coins3000.rawValue
            ) {
                vm.selectedProductId = PaywallItemType.coins3000.rawValue
            }

            CoinRow(
                title: "Elite Pack",
                subtitle: "7,200 Coins",
                badge: "Save More",
                rightBottom: "$19.99",
                isSelected: vm.selectedProductId == PaywallItemType.coins7200.rawValue
            ) {
                vm.selectedProductId = PaywallItemType.coins7200.rawValue
            }
        }
        .padding(.top, 6)
    }
}
