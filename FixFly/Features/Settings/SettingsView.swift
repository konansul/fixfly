import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    settingsSection {
                        Button { openMail() } label: {
                            settingsRow(title: "Contact Us", icon: "envelope")
                        }
                        
                        Button { rateApp() } label: {
                            settingsRow(title: "Rate Us", icon: "star")
                        }
                        
                        if let url = URL(string: ConfigAPI.appStoreURL) {
                            ShareLink(item: url) {
                                settingsRow(title: "Share App", icon: "square.and.arrow.up")
                            }
                        }
                    }
                    
                    settingsSection {
                        Button { restorePurchases() } label: {
                            settingsRow(title: "Restore Purchases", icon: "arrow.triangle.2.circlepath")
                        }
                    }
                    
                    settingsSection {
                        Button { openURL("https://tiktok.com/@fixfly") } label: {
                            settingsRow(title: "Follow us on TikTok", icon: "music.note")
                        }
                    }
                    
                    settingsSection {
                        Button { openURL(LegalLinks.privacyPolicy.absoluteString) } label: {
                            settingsRow(title: "Privacy Policy", icon: "hand.raised")
                        }

                        Button { openURL(LegalLinks.termsOfUse.absoluteString) } label: {
                            settingsRow(title: "Terms of Use", icon: "doc.text")
                        }
                    }

                    settingsSection {
                        Button { showDeleteConfirm = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.red)
                                    .frame(width: 22)
                                Text("Delete Account")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.001))
                        }
                    }

                    Text(appVersion)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            
            if isRestoring || isDeleting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().tint(.white).scaleEffect(1.2)
                        Text(isDeleting ? "Deleting..." : "Restoring...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.12)))
                }
                .zIndex(2)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restore Purchases", isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteAccount() }
        } message: {
            Text("This permanently deletes your account, coins and creations. This can't be undone.")
        }
    }
    
    private func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func settingsRow(title: String, icon: String, value: String? = nil, rightIcon: String? = "chevron.right") -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: 100, alignment: .trailing)
            }

            if let rightIcon = rightIcon {
                Image(systemName: rightIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.001))
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func openMail() {
        let subject = "FixFly Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let userID = AuthStore.shared.user?.id ?? "—"
        let body = "Please describe your issue below:\n\n\n\n--- \nApp Version: \(appVersion)\nUser ID: \(userID)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoURL = "mailto:konansulx@gmail.com?subject=\(subject)&body=\(body)"
        
        if let url = URL(string: mailtoURL) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        let urlString = "\(ConfigAPI.appStoreURL)?action=write-review"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }


    private func restorePurchases() {
        guard !isRestoring else { return }
        isRestoring = true

        Task {
            do {
                let count = try await StoreManager.shared.restore()
                await WalletManager.shared.refreshBalance()
                restoreMessage = count > 0
                    ? "Your purchases have been restored."
                    : "No active subscriptions found to restore."
            } catch {
                restoreMessage = "Couldn't restore purchases. Please try again."
            }
            isRestoring = false
        }
    }

    private func deleteAccount() {
        guard !isDeleting else { return }
        isDeleting = true

        Task {
            let ok = await AuthStore.shared.deleteAccount()
            isDeleting = false
            if ok { dismiss() }   // leave Settings; app continues with a fresh anonymous account
        }
    }
}
