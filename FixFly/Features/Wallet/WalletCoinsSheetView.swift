import SwiftUI

struct CoinsWalletSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = WalletSheetStore()
    @ObservedObject private var auth = AuthStore.shared
    @ObservedObject private var config = AppConfigStore.shared
    @State private var coinRotation: Double = 0

    var body: some View {
            NavigationStack {
                ZStack {
                    FixFlyBackground(imageName: "fixfly_bg")

                    Color.black.opacity(0.28)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 10) {
                                if !auth.isAuthed {
                                    // Guest: don't call the wallet API (it would 401) —
                                    // show a friendly sign-in prompt instead of a raw error.
                                    signedOutBlock
                                } else {
                                    balanceHero

                                    if let errorText = store.errorText {
                                        // 1. Если есть ошибка — показываем только её
                                        errorCard(errorText)
                                    } else if store.isLoading && store.items.isEmpty {
                                        // 2. Если ошибки нет и идет загрузка — показываем лоадер
                                        loadingBlock
                                    } else if store.items.isEmpty {
                                        // 3. Если загрузка завершена, ошибок нет, но список пуст — показываем "No transactions"
                                        emptyBlock
                                    } else {
                                        // 4. Во всех остальных случаях показываем список
                                        ledgerSection
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .padding(.bottom, 28)
                        }
                        .refreshable {
                            if auth.isAuthed { await store.load() }
                        }
                    }
                }
                .navigationTitle("Wallet")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if auth.isAuthed {
                                Task { await store.load() }
                            } else {
                                auth.requireSignIn()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .task {
                    startCoinAnimation()
                    if auth.isAuthed { await store.load() }
                }
                // After the guest signs in, load the wallet automatically.
                .onChange(of: auth.user?.id) { _, newId in
                    if newId != nil { Task { await store.load() } }
                }
            }
    }

    private var balanceHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.18))
                    .frame(width: 108, height: 108)
                    .blur(radius: 10)

                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 82))
                    .foregroundStyle(.yellow)
                    .rotation3DEffect(.degrees(coinRotation), axis: (x: 0, y: 1, z: 0))
            }

            Text("\(store.balance)")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)

            Text("Available coins")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

            HStack(spacing: 10) {
                infoChip(title: "Status", value: "Active")
                let countDisplay = store.items.count == 200 ? "200+" : "\(store.items.count)"
                infoChip(title: "Transactions", value: countDisplay)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(heroCardBackground)
    }

    /// Native Liquid Glass card on iOS 26+, translucent material below.
    @ViewBuilder
    private var heroCardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadius: 26))
        } else {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
    }

    private var ledgerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transactions")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            LazyVStack(spacing: 10) {
                ForEach(store.items) { item in
                    LedgerRowView(
                        item: item,
                        formattedDate: store.formattedDate(item.createdAt),
                        title: store.reasonTitle(item.reason),
                        subtitle: store.ledgerSubtitle(item)
                    )
                }
            }
        }
    }

    private var loadingBlock: some View {
        VStack(spacing: 12) {
            ProgressView().tint(.white)
            Text("Loading transactions...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var emptyBlock: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.7))

            Text("No transactions yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("Your coin history will appear here.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var signedOutBlock: some View {
        // Whether the backend is currently granting a signup bonus. When it is,
        // lead with the reward — the old copy only offered to "see your balance",
        // which is no reason to sign in.
        let bonus = config.signupBonusCoins

        return VStack(spacing: 14) {
            if bonus > 0 {
                HStack(spacing: 7) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("\(bonus) FREE COINS")
                        .font(.system(size: 13, weight: .heavy))
                        .tracking(0.5)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(FixFlyGradient.linear))
                .shadow(color: FixFlyGradient.accent.opacity(0.5), radius: 12)
            } else {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Text(bonus > 0 ? "Sign in and get \(bonus) free coins" : "You're not signed in")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(bonus > 0
                 ? "Enough to create your first AI photo — on us. Your coins and history stay saved across all your devices."
                 : "Sign in to see your coin balance and transaction history.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button {
                auth.requireSignIn()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Sign in with Apple")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .disabled(auth.isLoading)
            .opacity(auth.isLoading ? 0.5 : 1)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .padding(.top, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func errorCard(_ text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundStyle(.yellow)

            Text("Could not load wallet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await store.load() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func infoChip(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }

    private func startCoinAnimation() {
        coinRotation = 0
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
            coinRotation = 360
        }
    }
}
