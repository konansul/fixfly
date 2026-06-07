import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedToast = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    private var deviceID: String {
        if let serverID = AuthStore.shared.user?.id {
            return serverID
        }
        return AnonymousInstallID.getOrCreate()
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
                        
                        if let url = URL(string: "https://fixfly.app") {
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
                        Button { openURL("https://fixfly.app/privacy") } label: {
                            settingsRow(title: "Privacy Policy", icon: "hand.raised")
                        }
                        
                        Button { openURL("https://fixfly.app/terms") } label: {
                            settingsRow(title: "Terms of Use", icon: "doc.text")
                        }
                        
                        Button { copyDeviceID() } label: {
                            settingsRow(title: "Device ID", icon: "iphone", value: deviceID, rightIcon: "doc.on.doc")
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
            
            if showCopiedToast {
                VStack {
                    Spacer()
                    Text("Device ID copied to clipboard")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                        .padding(.bottom, 40)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(1)
            }

            if isRestoring {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().tint(.white).scaleEffect(1.2)
                        Text("Restoring...")
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
        let body = "Please describe your issue below:\n\n\n\n--- \nApp Version: \(appVersion)\nDevice ID: \(deviceID)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoURL = "mailto:konansul@gmail.com?subject=\(subject)&body=\(body)"
        
        if let url = URL(string: mailtoURL) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        let appID = "123456789"
        let urlString = "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func copyDeviceID() {
        UIPasteboard.general.string = deviceID
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation(.spring()) {
            showCopiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                showCopiedToast = false
            }
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
}
