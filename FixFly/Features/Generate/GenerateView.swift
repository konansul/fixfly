import SwiftUI

struct GenerateView: View {
    
    @State private var showPaywall = false
    
    let options = [
        GenerationOption(
            type: .image,
            title: "AI Photo",
            subtitle: "Generate images from text or photo",
            iconName: "photo.stack.fill",
            gradientColors: [FixFlyGradient.blue, FixFlyGradient.purple]
        ),
        
        GenerationOption(
            type: .video,
            title: "AI Video",
            subtitle: "Create cinematic videos from your prompts",
            iconName: "video.fill",
            gradientColors: [FixFlyGradient.purple, FixFlyGradient.pink]
        )
//        GenerationOption(
//            type: .music,
//            title: "AI Music",
//            subtitle: "Generate unique music tracks from description",
//            iconName: "waveform.and.mic",
//            gradientColors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.3, blue: 0.3)]
//        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.fixFlyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    
                    ScrollView(showsIndicators: false) {
                        
                        VStack(spacing: 20) {
                            
                            // Эту часть мы вообще не трогали, всё как у тебя
                            VStack(alignment: .leading, spacing: 5) {
                                
                                Text("Generate")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                
                                Text("What do you want to create today?")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                            }
                            
                            ForEach(options) { option in
                                GenerationMenuCard(option: option)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .toolbar {
                NavigationBar(showPaywall: $showPaywall)
            }
        }
    }
}

// Новый дизайн блоков (карточек)
struct GenerationMenuCard: View {
    let option: GenerationOption
    
    var body: some View {
        NavigationLink {
            destinationView(for: option.type)
        } label: {
            VStack(alignment: .leading, spacing: 20) {
                // Верхний ряд: Иконка и стрелочка
                HStack(alignment: .top) {
                    ZStack {
                        LinearGradient(
                            colors: option.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        
                        Image(systemName: option.iconName)
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 60, height: 60)
                    // Легкая тень от иконки в её же цвете
                    .shadow(color: option.gradientColors[0].opacity(0.4), radius: 8, x: 0, y: 4)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.top, 8)
                }
                
                // Нижний ряд: Текстовый блок
                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(option.subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.leading)
                        // Этот модификатор не дает тексту обрезаться или прятаться
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
            .background(
                ZStack {
                    // Основной полупрозрачный фон
                    Color.white.opacity(0.05)
                    
                    // Красивое легкое свечение в верхнем левом углу цвета самой опции
                    LinearGradient(
                        colors: [option.gradientColors[0].opacity(0.15), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func destinationView(for type: GenerationMediaType) -> some View {
        switch type {
        case .image:
            GeneratePhotoFormView()
        case .video:
            GenerateVideoFormView()
        case .music:
            GenerateMusicView() // На будущее, когда раскомментируешь музыку
        }
    }
}
