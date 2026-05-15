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
            async let ledgerTask = WalletAPI.shared.fetchLedger(limit: 200)

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
        switch reason {
        case "purchase":
            return "Coin Pack"
        case "subscription_grant":
            return "Subscription Bonus"
        case "veo_generation_start":
            return "AI Video Generation"
        case "veo_generation_refund":
            return "Refund: Video Failed"
        case "generation":
            return "AI Photo Generation"
        case "refund":
            return "Refund: Photo Failed"
        default:
            return reason.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    func ledgerSubtitle(_ item: WalletLedgerItem) -> String {
        if let meta = item.meta {
            if let style = meta["style"], style != "None" {
                return style.replacingOccurrences(of: "_", with: " ").capitalized
            }
            if let prompt = meta["prompt"] {
                return prompt
            }
        }
        
        switch item.reason {
        case "purchase":
            return "App Store Purchase"
        case "subscription_grant":
            return "Included in your plan"
        case "refund", "veo_generation_refund":
            return "Coins returned to balance"
        default:
            if item.amount > 0 {
                return "Added to wallet"
            } else {
                return "Digital art creation"
            }
        }
    }
}
