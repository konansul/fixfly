import SwiftUI

struct AppLoadingView: View {
    
    @StateObject private var viewModel = AppLoadingViewModel()

    @State private var logoScale: CGFloat = 0.94
    @State private var logoOpacity: Double = 0.85
    @State private var titleOffsetY: CGFloat = 10
    @State private var titleOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 18) {
                    Image("fixfly_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 86, height: 86)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                Spacer()

                VStack(spacing: 14) {
//                    Text("FixFly")
//                        .font(.system(size: 28, weight: .semibold))
//                        .foregroundStyle(Color.white)
//                        .opacity(titleOpacity)
//                        .offset(y: titleOffsetY)

                    ProgressBar(progress: viewModel.progress)
                        .frame(height: 6)
                        .padding(.horizontal, 80)
                }
                .padding(.bottom, 70)
            }
        }
        .task {
           // startAnimations()
            viewModel.startFakeProgress()
            await viewModel.preload()
        }
        .fullScreenCover(isPresented: $viewModel.isReady) {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }

//    private func startAnimations() {
//        withAnimation(.easeOut(duration: 0.7)) {
//            titleOpacity = 1
//            titleOffsetY = 0
//        }
//
//        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
//            logoScale = 1.03
//            logoOpacity = 1.0
//        }
//    }
}
