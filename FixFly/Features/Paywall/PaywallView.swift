import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PaywallViewModel()

    private var isCurrentPlanSelected: Bool {
        vm.activeSubscriptionId != nil && vm.selectedProductId == vm.activeSubscriptionId
    }

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
                    .padding(.top, 15)

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

            if let activeId = vm.activeSubscriptionId {
                let planName = activeId == PaywallItemType.weeklySub.rawValue ? "Weekly" : "Monthly"
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Your current plan is \(planName) Subscription")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
            } else {
                Text("Unlock the full power of FixFly subscriptions or one-time coin packs.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            modeSwitcher
                .padding(.top, 4)

            benefitsSection

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
                        Text(buttonTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(isCurrentPlanSelected ? Color.white.opacity(0.5) : Color.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(vm.isPurchasing || isCurrentPlanSelected)
            .padding(.top, 8)

            Text("Payment will be charged to your Apple ID account. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.bottom, 20)
        }
    }
    
    private var buttonTitle: String {
        if isCurrentPlanSelected {
            return "Current Plan"
        } else if vm.activeSubscriptionId != nil && vm.selectedProductId.contains("sub") {
            return "Switch Plan"
        } else {
            return vm.primaryButtonTitle
        }
    }

    private var modeSwitcher: some View {
        let isSub = vm.selectedProductId.contains("sub")
        return ZStack {
            Capsule()
                .fill(Color.white.opacity(0.08))

            GeometryReader { geo in
                let halfWidth = geo.size.width / 2
                Capsule()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: halfWidth - 4)
                    .offset(x: isSub ? 4 : halfWidth)
                    .animation(.easeInOut(duration: 0.35), value: isSub)
            }
            .padding(.vertical, 4)

            HStack(spacing: 0) {
                Button {
                    if !isSub {
                        triggerHaptic()
                        vm.selectedProductId = vm.activeSubscriptionId ?? PaywallItemType.weeklySub.rawValue
                    }
                } label: {
                    Text("Subscription")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.plain)
                
                Button {
                    if isSub {
                        triggerHaptic()
                        vm.selectedProductId = PaywallItemType.coins1200.rawValue
                    }
                } label: {
                    Text("Coins")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 52)
        .clipShape(Capsule())
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if vm.selectedProductId.contains("sub") {
                benefitRow(icon: "✨", text: "Priority generation speed")
                benefitRow(icon: "💧", text: "No watermarks")
                benefitRow(icon: "💎", text: "Unlock all Premium templates")
                
                if vm.selectedProductId == PaywallItemType.weeklySub.rawValue {
                    benefitRow(icon: "🎁", text: "2,400 Coins included every week")
                } else {
                    benefitRow(icon: "🎁", text: "7,200 Coins included every month")
                }
            } else {
                benefitRow(icon: "🪙", text: "One-time coin pack. Premium features not included.")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.2), value: vm.selectedProductId)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var subscriptionSection: some View {
        VStack(spacing: 12) {
            PlanRow(
                title: "Weekly",
                subtitle: "2,400 Coins",
                badge: vm.activeSubscriptionId == PaywallItemType.weeklySub.rawValue ? "Current Plan" : "Popular",
                rightTop: "per week",
                rightBottom: "$6.99",
                isSelected: vm.selectedProductId == PaywallItemType.weeklySub.rawValue
            ) {
                vm.selectedProductId = PaywallItemType.weeklySub.rawValue
            }

            PlanRow(
                title: "Monthly",
                subtitle: "7,200 Coins",
                badge: vm.activeSubscriptionId == PaywallItemType.monthlySub.rawValue ? "Current Plan" : "Best Value",
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
