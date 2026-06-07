//
//  WalletManager.swift
//  FixFly
//

import Foundation
import Combine

@MainActor
final class WalletManager: ObservableObject {

    static let shared = WalletManager()

    @Published var coins: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorText: String?

    private init() {}

    // загрузить баланс с backend
    func refreshBalance() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let balance = try await WalletAPI.shared.fetchBalance()
            self.coins = balance
        } catch {
            self.errorText = error.localizedDescription
            print("Wallet refresh failed:", error)
        }
    }

    // применить покупку
    func applyPurchase(
        productId: String,
        transactionId: String,
        originalTransactionId: String?,
        signedTransaction: String
    ) async throws {

        let payload = ApplyPurchaseRequest(
            provider: "appstore",
            productId: productId,
            transactionId: transactionId,
            originalTransactionId: originalTransactionId,
            amountCents: nil,
            currency: nil,
            raw: [:],
            signedTransaction: signedTransaction
        )

        let response = try await WalletAPI.shared.applyPurchase(payload)

        // backend вернет новый баланс
        self.coins = response.balance
    }

    // сброс при logout
    func clear() {
        coins = 0
        errorText = nil
    }
}
