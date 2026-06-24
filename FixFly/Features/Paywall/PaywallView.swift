import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PaywallViewModel()
    @ObservedObject private var auth = AuthStore.shared

    private var isCurrentPlanSelected: Bool {
        vm.activeSubscriptionId != nil && vm.selectedProductId == vm.activeSubscriptionId
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TemplateVideoWall()
                    .ignoresSafeArea()

                // Overall dim so titles/prices stay readable over the moving wall.
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.25),
                        Color.black.opacity(0.45),
                        Color.black.opacity(0.78),
                        Color.black.opacity(0.96),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                GeometryReader { geo in
                    ScrollView(showsIndicators: false) {
                        content
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .frame(maxWidth: 520)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: geo.size.height,
                                alignment: .bottom
                            )
                    }
                }
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .task {
                AppAnalytics.track(.paywallShown(source: "paywall"))
                await vm.loadProducts()
            }
            .onChange(of: vm.errorText) { _, newValue in
                if newValue != nil {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
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
            // A guest who tapped Buy gets the native Sign in with Apple sheet,
            // then the purchase resumes automatically — no second tap, no
            // intermediate gate screen.
            .onChange(of: auth.user?.id) { _, newId in
                if newId != nil, vm.resumePurchaseAfterSignIn {
                    vm.resumePurchaseAfterSignIn = false
                    Task { await vm.purchaseSelected() }
                }
            }
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

            planArea

            Button {
                Task {
                    let success = await vm.purchaseSelected()
                    if success {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
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
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .opacity(isCurrentPlanSelected ? 0.45 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(vm.isPurchasing || isCurrentPlanSelected)
            .padding(.top, 8)

            Text("Payment will be charged to your Apple ID account. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.45))

            HStack(spacing: 14) {
                Button {
                    Task { await vm.restore() }
                } label: {
                    Text("Restore Purchases")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Link("Privacy Policy", destination: LegalLinks.privacyPolicy)
                Link("Terms of Use", destination: LegalLinks.termsOfUse)
            }
            .font(.system(size: 11, weight: .semibold))
            .tint(.white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 20)
        }
    }
    
    /// Selects a product with the subtle selection tick (skips re-selection).
    private func select(_ productId: String) {
        guard vm.selectedProductId != productId else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        vm.selectedProductId = productId
    }

    /// Цена подписки из StoreKit (локализованная) + зачёркнутый «старый» якорь.
    /// Пока продукты грузятся — показываем сдержанный плейсхолдер.
    private func priceLabel(for productId: String) -> AnyView {
        AnyView(
            HStack(spacing: 4) {
                if let strike = vm.strikePrices[productId] {
                    Text(strike)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .strikethrough(true, color: .white.opacity(0.6))
                }

                Text(vm.displayPrices[productId] ?? "—")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        )
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
        GlassPillSwitcher(
            options: ["Subscription", "Coins"],
            selectedIndex: Binding(
                get: { vm.selectedProductId.contains("sub") ? 0 : 1 },
                set: { index in
                    if index == 0 {
                        vm.selectedProductId = vm.activeSubscriptionId ?? PaywallItemType.weeklySub.rawValue
                    } else {
                        vm.selectedProductId = PaywallItemType.coins1200.rawValue
                    }
                }
            )
        )
    }

    private var isSubscriptionMode: Bool { vm.selectedProductId.contains("sub") }

    /// Зона «бенефиты + список планов». Невидимый призрак из обоих режимов
    /// фиксирует высоту по самому высокому варианту, а реальный контент
    /// прижимается к низу (к кнопке Subscribe) — свободное место копится
    /// сверху, под переключателем Subscription/Coins.
    private var planArea: some View {
        ZStack {
            variableStack(forSubscription: true)
            variableStack(forSubscription: false)
        }
        .hidden()
        .overlay {
            // Натуральная высота группы, прижатая к низу зоны; слабина сверху.
            VStack(alignment: .leading, spacing: 16) {
                currentBenefits
                currentSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .animation(.easeInOut(duration: 0.25), value: isSubscriptionMode)
    }

    /// Натуральная высота режима — используется только призраком для измерения.
    @ViewBuilder
    private func variableStack(forSubscription sub: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitsContent(forSubscription: sub, weekly: true)
                .padding(.horizontal, 4)
            if sub { subscriptionSection } else { coinSection }
        }
    }

    private var currentBenefits: some View {
        benefitsContent(
            forSubscription: isSubscriptionMode,
            weekly: vm.selectedProductId == PaywallItemType.weeklySub.rawValue
        )
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.2), value: vm.selectedProductId)
    }

    private var currentSection: some View {
        ZStack {
            if isSubscriptionMode {
                subscriptionSection
                    .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .move(edge: .trailing).combined(with: .opacity)))
            } else {
                coinSection
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
    }

    @ViewBuilder
    private func benefitsContent(forSubscription: Bool, weekly: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if forSubscription {
                benefitRow(icon: "✨", text: "Priority generation speed")
                
                benefitRow(icon: "💧", text: "No watermarks")
                
                benefitRow(icon: "💎", text: "Unlock all Premium templates")

                if weekly {
                    benefitRow(icon: "🎁", text: "2,400 Coins included every week")
                } else {
                    benefitRow(icon: "🎁", text: "7,200 Coins included every month")
                }
            } else {
                benefitRow(icon: "🪙", text: "One-time coin packs")
            }
        }
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
                    rightBottom: priceLabel(for: PaywallItemType.weeklySub.rawValue),
                    isSelected: vm.selectedProductId == PaywallItemType.weeklySub.rawValue
                ) {
                    select(PaywallItemType.weeklySub.rawValue)
                }

                PlanRow(
                    title: "Monthly",
                    subtitle: "7,200 Coins",
                    badge: vm.activeSubscriptionId == PaywallItemType.monthlySub.rawValue ? "Current Plan" : "Best Value",
                    rightTop: "per month",
                    rightBottom: priceLabel(for: PaywallItemType.monthlySub.rawValue),
                    isSelected: vm.selectedProductId == PaywallItemType.monthlySub.rawValue
                ) {
                    select(PaywallItemType.monthlySub.rawValue)
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
                rightBottom: vm.displayPrices[PaywallItemType.coins1200.rawValue] ?? "—",
                isSelected: vm.selectedProductId == PaywallItemType.coins1200.rawValue
            ) {
                select(PaywallItemType.coins1200.rawValue)
            }

            CoinRow(
                title: "Pro Pack",
                subtitle: "3,000 Coins",
                badge: "Best Seller",
                rightBottom: vm.displayPrices[PaywallItemType.coins3000.rawValue] ?? "—",
                isSelected: vm.selectedProductId == PaywallItemType.coins3000.rawValue
            ) {
                select(PaywallItemType.coins3000.rawValue)
            }

            CoinRow(
                title: "Elite Pack",
                subtitle: "7,200 Coins",
                badge: "Save More",
                rightBottom: vm.displayPrices[PaywallItemType.coins7200.rawValue] ?? "—",
                isSelected: vm.selectedProductId == PaywallItemType.coins7200.rawValue
            ) {
                select(PaywallItemType.coins7200.rawValue)
            }
        }
        .padding(.top, 6)
    }
}
