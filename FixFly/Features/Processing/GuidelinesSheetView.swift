import SwiftUI

struct PhotoGuidelinesSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Generation Guidelines")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Follow the rules below for the best AI results")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 16) {
                    guidelineCard(
                        isGood: true,
                        title: "Good",
                        subtitle: "Clear face\nGood lighting",
                        color: .green
                    )
                    
                    guidelineCard(
                        isGood: false,
                        title: "Bad",
                        subtitle: "Hidden face\nBlurry or far",
                        color: .red
                    )
                }
                .padding(.horizontal, 20)

                
                Button {
                    SessionManager.shared.hasSeenPhotoGuidelinesThisSession = true
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onContinue()
                    }
                } label: {
                    Text("Choose Media")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.55, green: 0.25, blue: 1.0), Color(red: 1.0, green: 0.35, blue: 0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func guidelineCard(isGood: Bool, title: String, subtitle: String, color: Color) -> some View {
        ZStack(alignment: .top) {
            Image(isGood ? "goodphoto" : "badphoto")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 260)
                .clipped()
            
            HStack(spacing: 6) {
                Image(systemName: isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(color)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack {
                Spacer()
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.7), Color.black.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.6), lineWidth: 2)
        )
    }
}
