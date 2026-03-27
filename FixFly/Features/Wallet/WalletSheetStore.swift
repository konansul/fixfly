//
//  WalletSheetStore.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//

//
//  WalletSheetStore.swift
//  FixFly
//

import Foundation
import Combine

@MainActor
final class WalletSheetStore: ObservableObject {
    @Published var balance: Int = 0
    @Published var items: [WalletLedgerItem] = []
    @Published var isLoading = false
    @Published var errorText: String?

    
    private let dateFormatterIn: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let dateFormatterInFallback: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private let dateFormatterOut: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    func load() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            async let balanceTask = WalletAPI.shared.fetchBalance()
            async let ledgerTask = WalletAPI.shared.fetchLedger(limit: 100)

            let (balanceValue, ledgerItems) = try await (balanceTask, ledgerTask)

            balance = balanceValue
            items = ledgerItems

            WalletManager.shared.coins = balanceValue
        } catch {
            errorText = error.localizedDescription
        }
    }

    func formattedDate(_ raw: String?) -> String {
        guard let raw else { return "Unknown date" }
        if let date = dateFormatterIn.date(from: raw) { return dateFormatterOut.string(from: date) }
        if let date = dateFormatterInFallback.date(from: raw) { return dateFormatterOut.string(from: date) }
        return raw
    }

    func reasonTitle(_ reason: String) -> String {
        switch reason.lowercased() {
        case "generation": return "Generation"
        case "purchase": return "Purchase"
        case "subscription": return "Subscription"
        case "reward": return "Reward"
        default: return reason.capitalized
        }
    }

    func ledgerSubtitle(_ item: WalletLedgerItem) -> String {
        if let feature = item.meta?["feature_key"] as? String {
            return feature.replacingOccurrences(of: "_", with: " ").capitalized
        }
        if let product = item.meta?["product_id"] as? String {
            return product
        }
        return item.reason.capitalized
    }
}
