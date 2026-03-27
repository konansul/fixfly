//
//  WalletAPI.swift
//  FixFly
//

import Foundation

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let dictValue as [String: AnyCodable]:
            try container.encode(dictValue)
        case let arrayValue as [AnyCodable]:
            try container.encode(arrayValue)
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - API

final class WalletAPI {
    static let shared = WalletAPI()
    private init() {}

    func fetchBalance() async throws -> Int {
        let response: WalletBalanceResponse = try await ClientAPI.shared.get(
            "/v1/wallet",
            requiresAuth: true
        )
        return response.balance
    }

    func fetchLedger(limit: Int = 50) async throws -> [WalletLedgerItem] {
        let response: WalletLedgerResponse = try await ClientAPI.shared.get(
            "/v1/wallet/ledger?limit=\(limit)",
            requiresAuth: true
        )
        return response.items
    }

    func applyPurchase(_ payload: ApplyPurchaseRequest) async throws -> ApplyPurchaseResponse {
        let jsonBody: [String: Any] = [
            "provider": payload.provider,
            "product_id": payload.productId,
            "transaction_id": payload.transactionId,
            "original_transaction_id": payload.originalTransactionId as Any,
            "amount_cents": payload.amountCents as Any,
            "currency": payload.currency as Any,
            "raw": payload.raw
        ]

        let response: ApplyPurchaseResponse = try await ClientAPI.shared.post(
            "/v1/store/apply-purchase",
            jsonBody: jsonBody,
            requiresAuth: true
        )

        return response
    }
}
