import SwiftUI

struct NavigationBar: ToolbarContent {
    @Binding var showPaywall: Bool
    @StateObject private var auth = AuthStore.shared
    @State private var showCoinsSheet = false

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showCoinsSheet = true
            } label: {
                CoinsBadge()
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showCoinsSheet) {
                CoinsWalletSheetView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            Button {
                showPaywall = true
            } label: {
                ProButton()
                    .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: false)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct CoinsBadge: View {
    @StateObject private var wallet = WalletManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.yellow)

            Text("\(wallet.coins)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .fixedSize(horizontal: true, vertical: false)
    }
}
