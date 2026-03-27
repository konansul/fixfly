import SwiftUI
import StoreKit
import Combine

enum PaywallItemType: String, CaseIterable, Identifiable {
    case weeklySub = "weekly_sub"
    case monthlySub = "monthly_sub"
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
    }

    func restore() async {
        do {
            try await store.restore()
        } catch {
            errorText = error.localizedDescription
        }
    }

    func purchaseSelected() async -> Bool {
        guard store.isReady else { return false }
        
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
            
            return true
        } catch {
            errorText = error.localizedDescription
            return false
        }
    }
}
