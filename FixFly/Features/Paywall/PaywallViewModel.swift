import SwiftUI
import StoreKit
import Combine

enum PaywallItemType: String, CaseIterable, Identifiable {
    case weeklySub = "weekly_sub2"
    case monthlySub = "monthly_sub2"
    case coins1200 = "coins_1200"
    case coins3000 = "coins_3000"
    case coins7200 = "coins_7200"
    
    var id: String { self.rawValue }
    
    var isSubscription: Bool {
        self == .weeklySub || self == .monthlySub
    }
}

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var selectedProductId: String = PaywallItemType.weeklySub.rawValue
    @Published var isPurchasing = false
    @Published var errorText: String?
    @Published var activeSubscriptionId: String?

    /// Локализованные цены прямо из StoreKit (валюта/формат витрины пользователя).
    /// Пусто, пока продукты не загрузились — UI показывает плейсхолдер.
    @Published var displayPrices: [String: String] = [:]
    /// Зачёркнутая «старая» цена для подписок (маркетинговый якорь), в той же валюте.
    @Published var strikePrices: [String: String] = [:]

    private let store = StoreManager.shared

    var primaryButtonTitle: String {
        if isPurchasing { return "Processing..." }
        
        switch selectedProductId {
        case PaywallItemType.weeklySub.rawValue: return "Subscribe Weekly"
        case PaywallItemType.monthlySub.rawValue: return "Subscribe Monthly"
        case PaywallItemType.coins1200.rawValue: return "Buy 1,200 Coins"
        case PaywallItemType.coins3000.rawValue: return "Buy 3,000 Coins"
        case PaywallItemType.coins7200.rawValue: return "Buy 7,200 Coins"
        default: return "Continue"
        }
    }

    func loadProducts() async {
        await store.loadProductsIfNeeded()
        refreshPrices()
        await checkActiveSubscription()
    }

    /// Перечитывает локализованные цены из загруженных StoreKit-продуктов.
    private func refreshPrices() {
        var prices: [String: String] = [:]
        var strikes: [String: String] = [:]

        for type in PaywallItemType.allCases {
            guard let product = store.product(for: type.rawValue) else { continue }
            prices[type.rawValue] = product.displayPrice

            // Зачёркнутая «была» цена ~1.5x от реальной, в той же валюте/формате.
            if type.isSubscription {
                let original = product.price * 1.5
                strikes[type.rawValue] = original.formatted(product.priceFormatStyle)
            }
        }

        displayPrices = prices
        strikePrices = strikes
    }

    func restore() async {
        do {
            try await store.restore()
            await checkActiveSubscription()
        } catch {
            errorText = error.localizedDescription
        }
    }

    func purchaseSelected() async -> Bool {
        // Sign in with Apple is required before buying — coins/subscriptions are
        // tied to the account. A guest gets the sign-in sheet instead.
        guard AuthStore.shared.requireSignIn() else { return false }

        // Продукты могли не загрузиться при открытии (нет сети / конфигурация
        // App Store Connect) — пробуем ещё раз и показываем ошибку вместо
        // молчаливого выхода.
        if !store.isReady {
            await store.loadProductsIfNeeded()
        }
        guard store.isReady else {
            errorText = store.loadError ?? StoreError.notAvailable.errorDescription
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            guard let type = PaywallItemType(rawValue: selectedProductId) else { return false }
            
            if type.isSubscription {
                if type == .weeklySub {
                    try await store.buyWeekly()
                } else {
                    try await store.buyMonthly()
                }
            } else {
                try await store.buyCoins(productId: selectedProductId)
            }
            
            await checkActiveSubscription()
            AppAnalytics.track(.purchaseSuccess(productId: selectedProductId))
            return true
        } catch {
            errorText = error.localizedDescription
            AppAnalytics.track(.purchaseFailed(productId: selectedProductId, reason: error.localizedDescription))
            return false
        }
    }
    
    private func checkActiveSubscription() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if transaction.revocationDate != nil { continue }
            
            if transaction.productID == PaywallItemType.weeklySub.rawValue ||
               transaction.productID == PaywallItemType.monthlySub.rawValue {
                
                self.activeSubscriptionId = transaction.productID
                
                self.selectedProductId = transaction.productID
                return
            }
        }
        
        self.activeSubscriptionId = nil
    }
}
