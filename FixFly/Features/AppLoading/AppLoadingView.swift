import SwiftUI

struct AppLoadingView: View {
    @StateObject private var viewModel = AppLoadingViewModel()
    @ObservedObject private var auth = AuthStore.shared

    @State private var logoScale: CGFloat = 0.94
    @State private var logoOpacity: Double = 0.85
    @State private var titleOffsetY: CGFloat = 10
    @State private var titleOpacity: Double = 0.0

    var body: some View {
        // Sign in with Apple is mandatory: an authed user goes straight to the
        // app, everyone else must complete onboarding (which can't be skipped).
        // Deleting the account drops `user` to nil and lands back here.
        if viewModel.isReady {
            if auth.user != nil {
                MainTabView()
                    .preferredColorScheme(.dark)
                    .transition(.opacity)
            } else {
                OnboardingView()
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
