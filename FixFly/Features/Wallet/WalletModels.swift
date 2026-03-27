//
//  WalletModels.swift
//  FixFly
//
//  Created by Kanan Sultanov on 07.03.26.
//

import Foundation

struct WalletBalanceResponse: Decodable {
    let balance: Int
}

struct WalletLedgerResponse: Decodable {
    let items: [WalletLedgerItem]
}

struct WalletLedgerItem: Decodable, Identifiable {
    let id: String
    let amount: Int
    let reason: String
    let refType: String?
    let refId: String?
    let meta: [String: String]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case reason
        case refType = "ref_type"
        case refId = "ref_id"
        case meta
        case createdAt = "created_at"
    }
}

struct ApplyPurchaseRequest: Encodable {
    let provider: String
    let productId: String
    let transactionId: String
    let originalTransactionId: String?
    let amountCents: Int?
    let currency: String?
    let raw: [String: String]

    enum CodingKeys: String, CodingKey {
        case provider
        case productId = "product_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case amountCents = "amount_cents"
        case currency
        case raw
    }
}

struct ApplyPurchaseResponse: Decodable {
    let ok: Bool
    let alreadyProcessed: Bool
    let productId: String?
    let creditsGranted: Int?
    let balance: Int

    enum CodingKeys: String, CodingKey {
        case ok
        case alreadyProcessed = "already_processed"
        case productId = "product_id"
        case creditsGranted = "credits_granted"
        case balance
    }
}
