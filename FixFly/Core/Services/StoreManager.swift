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

    private let weeklyID = "weekly_sub"
    private let monthlyID = "monthly_sub"

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

    var weeklyDisplayPrice: String? { weekly?.displayPrice }
    var monthlyDisplayPrice: String? { monthly?.displayPrice }

    func displayPrice(for productId: String) -> String? {
        if productId == weeklyID { return weekly?.displayPrice }
        if productId == monthlyID { return monthly?.displayPrice }
        return coinProducts[productId]?.displayPrice
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
        } catch {
            isReady = false
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

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verification.payloadValue
            try await applyTransactionToBackend(transaction)
            await transaction.finish()

        case .userCancelled:
            throw StoreError.cancelled

        case .pending:
            throw StoreError.pending

        @unknown default:
            throw StoreError.unknown
        }
    }

    func restore() async throws {
        try await AppStore.sync()
    }

    private func applyTransactionToBackend(_ transaction: StoreKit.Transaction) async throws {
        let transactionId = String(transaction.id)
        let originalTransactionId = String(transaction.originalID)

        try await WalletManager.shared.applyPurchase(
            productId: transaction.productID,
            transactionId: transactionId,
            originalTransactionId: originalTransactionId
        )
    }

    private func observeTransactionUpdates() {
        updatesTask?.cancel()
        updatesTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try result.payloadValue
                    if AuthStore.shared.isAuthed {
                        try await applyTransactionToBackend(transaction)
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
