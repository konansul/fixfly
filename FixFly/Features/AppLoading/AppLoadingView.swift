import SwiftUI

struct AppLoadingView: View {
    @StateObject private var viewModel = AppLoadingViewModel()

    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    // Explicit AI data-sharing consent (App Review 5.1.1(i)/5.1.2(i)). Shown once,
    // after onboarding, before the app can send any photo to an AI provider.
    @AppStorage("ai_data_consent_v1") private var aiConsent = false

    @State private var logoScale: CGFloat = 0.94
    @State private var logoOpacity: Double = 0.85
    @State private var titleOffsetY: CGFloat = 10
    @State private var titleOpacity: Double = 0.0

    var body: some View {
        // Guests can browse: after onboarding (which is skippable) we go to the
        // main app whether or not the user signed in. Sign in with Apple is
        // required only at a value action (Generate / Buy), gated there.
        if viewModel.isReady {
            if !onboardingCompleted {
                OnboardingView {
                    withAnimation { onboardingCompleted = true }
                }
                .preferredColorScheme(.dark)
                .transition(.opacity)
            } else if !aiConsent {
                // Explicit permission before any photo is sent to an AI provider.
                AIConsentGateView {
                    withAnimation { aiConsent = true }
                }
                .transition(.opacity)
            } else {
                MainTabView()
                    .preferredColorScheme(.dark)
                    .transition(.opacity)
            }
        } else {
            // Иначе показываем экран загрузки
            loadingScreen
                .transition(.opacity) // Плавное исчезновение
                .task {
                    viewModel.startFakeProgress()
                    await viewModel.preload()
                }
        }
    }
    
    private var loadingScreen: some View {
        ZStack {
//            // Uniform dark navy matching the app icon background (was flat black).
//            Color(red: 0.02, green: 0.04, blue: 0.09)
//                .ignoresSafeArea()
//                .allowsHitTesting(false)

            Color(.black)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 18) {
                    Image("fixfly_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 190, height: 190)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                Spacer()

                VStack(spacing: 14) {
                    ProgressBar(progress: viewModel.progress)
                        .frame(height: 6)
                        .padding(.horizontal, 80)
                }
                .padding(.bottom, 70)
            }
        }
    }
}
