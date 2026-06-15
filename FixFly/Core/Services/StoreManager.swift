import Foundation
import StoreKit
import Combine

@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()
    private var updatesTask: Task<Void, Never>?

    private init() {
        observeTransactionUpdates()
    }

    // weekly_sub/monthly_sub были удалены в App Store Connect, а Apple навсегда
    // блокирует Product ID удалённых подписок — поэтому версии с суффиксом 2.
    private let weeklyID = "weekly_sub2"
    private let monthlyID = "monthly_sub2"

    private let coinIDs: [String] = [
        "coins_1200",
        "coins_3000",
        "coins_7200"
    ]

    private var allIDs: [String] { [weeklyID, monthlyID] + coinIDs }

    @Published private(set) var weekly: Product?
    @Published private(set) var monthly: Product?
    @Published private(set) var coinProducts: [String: Product] = [:]
    @Published private(set) var isReady: Bool = false
    @Published private(set) var loadError: String?

    var weeklyDisplayPrice: String? { weekly?.displayPrice }
    var monthlyDisplayPrice: String? { monthly?.displayPrice }

    func displayPrice(for productId: String) -> String? {
        product(for: productId)?.displayPrice
    }

    func product(for productId: String) -> Product? {
        if productId == weeklyID { return weekly }
        if productId == monthlyID { return monthly }
        return coinProducts[productId]
    }

    func loadProductsIfNeeded() async {
        guard !isReady else { return }

        do {
            let products = try await Product.products(for: allIDs)

            weekly = products.first(where: { $0.id == weeklyID })
            monthly = products.first(where: { $0.id == monthlyID })

            var coins: [String: Product] = [:]
            for id in coinIDs {
                if let product = products.first(where: { $0.id == id }) {
                    coins[id] = product
                }
            }
            coinProducts = coins

            isReady = (weekly != nil) || (monthly != nil) || !coinProducts.isEmpty
            // Запрос прошёл, но App Store не вернул ни одного продукта — почти
            // всегда это конфигурация App Store Connect (продукты не созданы /
            // Missing Metadata / договор Paid Applications не активен).
            loadError = isReady ? nil : "Products not found in App Store. Check In-App Purchase setup in App Store Connect."
            if !isReady {
                print("StoreKit: no products returned for ids \(allIDs)")
            }
        } catch {
            isReady = false
            loadError = error.localizedDescription
            print("StoreKit: product load failed: \(error)")
        }
    }

    func buyWeekly() async throws {
        guard let weekly else { throw StoreError.notAvailable }
        try await purchase(product: weekly)
    }

    func buyMonthly() async throws {
        guard let monthly else { throw StoreError.notAvailable }
        try await purchase(product: monthly)
    }

    func buyCoins(productId: String) async throws {
        guard let product = coinProducts[productId] else {
            throw StoreError.notAvailable
        }
        try await purchase(product: product)
    }

    private func purchase(product: Product) async throws {
        guard AuthStore.shared.isAuthed else {
            throw StoreError.notAuthenticated
        }

        // Tag the purchase with the backend user id (a UUID) so App Store Server
        // Notifications can be mapped back to this user for renewals.
        var options: Set<Product.PurchaseOption> = []
        if let idString = AuthStore.shared.user?.id, let uuid = UUID(uuidString: idString) {
            options.insert(.appAccountToken(uuid))
        }

        let result = try await product.purchase(options: options)

        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            try await applyTransactionToBackend(transaction, jws: verification.jwsRepresentation)
            await transaction.finish()

        case .userCancelled:
            throw StoreError.cancelled

        case .pending:
            throw StoreError.pending

        @unknown default:
            throw StoreError.unknown
        }
    }

    /// Explicit "Restore Purchases" (Settings button). Calls AppStore.sync(),
    /// which prompts for the Apple ID password — so ONLY call this from a user
    /// action, never automatically. Re-applies active entitlements to the
    /// backend so Pro access is re-granted on a new device / reinstall.
    /// Returns the number of active entitlements that were restored.
    @discardableResult
    func restore() async throws -> Int {
        guard AuthStore.shared.isAuthed else {
            throw StoreError.notAuthenticated
        }

        // Force a refresh from the App Store. NOTE: this prompts for the Apple
        // ID password — acceptable here because the user tapped "Restore".
        try await AppStore.sync()

        return await reapplyEntitlements()
    }

    /// Silently re-applies active entitlements (subscriptions) to the backend
    /// from the local StoreKit cache. Unlike restore() this does NOT call
    /// AppStore.sync(), so it never prompts for the Apple ID password — safe to
    /// call automatically after login / on launch.
    @discardableResult
    func reapplyEntitlements() async -> Int {
        guard AuthStore.shared.isAuthed else { return 0 }

        var count = 0
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }

            try? await applyTransactionToBackend(transaction, jws: result.jwsRepresentation)
            count += 1
        }
        return count
    }

    private func applyTransactionToBackend(_ transaction: StoreKit.Transaction, jws: String) async throws {
        let transactionId = String(transaction.id)
        let originalTransactionId = String(transaction.originalID)

        try await WalletManager.shared.applyPurchase(
            productId: transaction.productID,
            transactionId: transactionId,
            originalTransactionId: originalTransactionId,
            signedTransaction: jws
        )
    }

    private func observeTransactionUpdates() {
        updatesTask?.cancel()
        updatesTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try result.payloadValue
                    if AuthStore.shared.isAuthed {
                        try await applyTransactionToBackend(transaction, jws: result.jwsRepresentation)
                    }
                    await transaction.finish()
                } catch {
                    print("Update error: \(error)")
                }
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }
}

enum StoreError: LocalizedError {
    case notAvailable
    case notAuthenticated
    case cancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "Products are not available yet."
        case .notAuthenticated: return "Please sign in first."
        case .cancelled: return "Purchase cancelled."
        case .pending: return "Purchase pending."
        case .unknown: return "Unknown purchase error."
        }
    }
}
