import SwiftUI

struct GenerateView: View {
    
    @State private var showPaywall = false
    
    let options = [
        GenerationOption(
            type: .image,
            title: "AI Photo",
            subtitle: "Generate images from text or reference photo",
            iconName: "photo.stack.fill",
            gradientColors: [Color(red: 0.44, green: 0.28, blue: 1.00), Color(red: 0.26, green: 0.67, blue: 1.00)]
        ),
        GenerationOption(
            type: .video,
            title: "AI Video",
            subtitle: "Create cinematic videos from your prompts",
            iconName: "video.fill",
            gradientColors: [Color(red: 0.94, green: 0.33, blue: 0.87), Color(red: 1.0, green: 0.35, blue: 0.85)]
        ),
        GenerationOption(
            type: .music,
            title: "AI Music",
            subtitle: "Generate unique music tracks from description",
            iconName: "waveform.and.mic",
            gradientColors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.3, blue: 0.3)]
        )
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
                            
                            VStack(alignment: .leading, spacing: 5) {
                                
                                Text("Generate")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                
                                Text("What do you want to create today?")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
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
            .toolbar {
                NavigationBar(showPaywall: $showPaywall)
            }
        }
    }
}

struct GenerationMenuCard: View {
    let option: GenerationOption
    
    var body: some View {
        NavigationLink {
            destinationView(for: option.type)
        } label: {
            HStack(spacing: 16) {
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
                .frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(option.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func destinationView(for type: GenerationMediaType) -> some View {
        switch type {
        case .image, .video:
            GeneratePhotoVideoFormView(initialMediaType: type)
        case .music:
            GenerateMusicView()
        }
    }
}
