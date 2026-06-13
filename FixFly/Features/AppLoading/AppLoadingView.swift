import SwiftUI

struct AppLoadingView: View {
    @StateObject private var viewModel = AppLoadingViewModel()

    @State private var logoScale: CGFloat = 0.94
    @State private var logoOpacity: Double = 0.85
    @State private var titleOffsetY: CGFloat = 10
    @State private var titleOpacity: Double = 0.0

    var body: some View {
        // Проверяем состояние: если готово - показываем главный экран
        if viewModel.isReady {
            MainTabView()
                .preferredColorScheme(.dark)
                // Опционально: добавляем плавное растворение экрана загрузки
                // Если хочешь мгновенное переключение без анимации, удали .transition
                .transition(.opacity)
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
            // Uniform dark navy matching the app icon background (was flat black).
            Color(red: 0.02, green: 0.04, blue: 0.09)
                .ignoresSafeArea()
                .allowsHitTesting(false)

//            Color.black.opacity(0.18)
//                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 18) {
                    Image("fixfly_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
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
