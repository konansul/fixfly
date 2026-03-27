import SwiftUI

struct GenerateMusicView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var prompt: String = ""
    @State private var weight: Double = 1.0
    @State private var bpm: Double = 120.0
    @State private var isPlaying: Bool = false

    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Live Prompt")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))

                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )

                                if prompt.isEmpty {
                                    Text("e.g. minimal techno, 808 Hip Hop Beat, Piano...")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white.opacity(0.4))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }

                                TextEditor(text: $prompt)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .frame(height: 120)
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("BPM")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Spacer()
                                Text("\(Int(bpm))")
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Slider(value: $bpm, in: 60...200, step: 1)
                                .tint(Color(red: 1.0, green: 0.6, blue: 0.2))
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Prompt Weight")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                Spacer()
                                Text(String(format: "%.1f", weight))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Slider(value: $weight, in: 0.1...5.0, step: 0.1)
                                .tint(Color(red: 1.0, green: 0.6, blue: 0.2))
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 20)
                }

                Button {
                    withAnimation {
                        isPlaying.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        Text(isPlaying ? "Stop Stream" : "Start Streaming")
                            .font(.system(size: 18, weight: .bold))

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "bitcoinsign.circle.fill")
                            Text("300")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                    }
                    .foregroundStyle(.white)
                    .padding(.leading, 24)
                    .padding(.trailing, 8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: isPlaying ? [Color.red, Color.pink] : [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.3, blue: 0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AI Music DJ    ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 6) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.yellow)

                    Text("\(WalletManager.shared.coins)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        }
    }
}
