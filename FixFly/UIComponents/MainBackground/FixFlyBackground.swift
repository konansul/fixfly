//  FixFlyBackground.swift
//  FixFly
//
//  Created by Kanan Sultanov on 12.03.26.
//
//  Soft animated glow background, in the spirit of PhotoProcessingView's
//  pulsing blurred circle. Three glow blobs (blue / pink / purple) live in
//  the top third of the screen over a muted near-black base. Each blob
//  breathes — fades out and re-ignites on a ~3.5 s cycle — and slowly
//  re-colours along the blue → pink → purple loop. The pulse and colour
//  phases are offset by a third per blob, so all three hues are always on
//  screen at once and the colours appear to wander between the blobs.
//
//  The blobs are radial-gradient fills rather than `.blur`-ed circles:
//  visually the same soft glow, but far cheaper to animate every frame.
//  A vertical mask fades the glow layer out by mid-screen, so the lower
//  half stays one uniform muted dark with no seam.
//

import SwiftUI

struct FixFlyBackground: View {
    // Kept for source compatibility with existing call sites. No longer used.
    var height: CGFloat = 440
    var startFade: CGFloat = 0.20
    var imageName: String = "fixfly_bg"

    var body: some View {
        GlowBlobsBackground()
            .ignoresSafeArea()
    }
}

// MARK: - Glow blobs

private struct GlowBlobsBackground: View {

    /// The "black" of the app: a muted near-black so the lower half reads as
    /// black, never true `(0,0,0)` (avoids banding). The turquoise/blue glow
    /// blobs still light up the top third over it.
    private static let baseColor = Color(red: 0.008, green: 0.008, blue: 0.012)

    /// Anchor hues the blobs cycle through: turquoise → sky → blue → (loops).
    private static let hueCycle: [SIMD3<Double>] = [
        SIMD3(0.22, 0.86, 0.97),   // turquoise / cyan
        SIMD3(0.26, 0.64, 0.99),   // sky blue
        SIMD3(0.13, 0.45, 0.97),   // deep blue
    ]

    /// One breath (fade out → re-ignite) per blob.
    private static let pulsePeriod: Double = 3.5
    /// Full blue → pink → purple → blue colour loop per blob.
    private static let colorPeriod: Double = 10.0

    /// Blob layout in unit coordinates; radius is a fraction of screen width.
    /// `phase` (in thirds) offsets both the pulse and the colour position, so
    /// the three blobs are always at different points of both cycles.
    private struct Blob {
        let center: CGPoint
        let radius: CGFloat
        let phase: Double
    }

    private static let blobs: [Blob] = [
        Blob(center: CGPoint(x: 0.18, y: 0.08), radius: 0.62, phase: 0.0),
        Blob(center: CGPoint(x: 0.84, y: 0.05), radius: 0.55, phase: 1.0 / 3.0),
        Blob(center: CGPoint(x: 0.52, y: 0.20), radius: 0.68, phase: 2.0 / 3.0),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ZStack {
                    Self.baseColor

                    ZStack {
                        ForEach(0..<Self.blobs.count, id: \.self) { i in
                            blobView(Self.blobs[i], at: t, in: geo.size)
                        }
                    }
                    .mask(topFadeMask)
                }
            }
        }
    }

    /// One glowing blob: a radial colour-to-clear gradient that breathes
    /// (opacity + scale) and slowly re-colours along the hue cycle.
    private func blobView(_ blob: Blob, at t: Double, in size: CGSize) -> some View {
        let pulse = breath(at: t, phase: blob.phase)
        let color = hue(at: t, phase: blob.phase)
        let r = blob.radius * size.width

        return Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.85), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: r
                )
            )
            .frame(width: r * 2, height: r * 2)
            .scaleEffect(0.92 + 0.16 * pulse)
            .opacity(0.30 + 0.70 * pulse)
            .position(x: blob.center.x * size.width, y: blob.center.y * size.height)
    }

    /// 0…1 breathing curve. Phases are a third apart, so when one blob is at
    /// its dimmest another is near its brightest — the glow never dies out.
    private func breath(at t: Double, phase: Double) -> Double {
        0.5 + 0.5 * sin(2 * .pi * (t / Self.pulsePeriod + phase))
    }

    /// Current colour of a blob: position along the blue → pink → purple loop,
    /// blended between the two nearest anchors. The same third-of-a-cycle
    /// phase offset keeps all three hues on screen simultaneously.
    private func hue(at t: Double, phase: Double) -> Color {
        let n = Double(Self.hueCycle.count)
        var pos = (t / Self.colorPeriod + phase) * n
        pos = pos.truncatingRemainder(dividingBy: n)
        if pos < 0 { pos += n }
        let i = Int(pos) % Self.hueCycle.count
        let j = (i + 1) % Self.hueCycle.count
        let f = pos - pos.rounded(.down)
        let rgb = Self.hueCycle[i] + (Self.hueCycle[j] - Self.hueCycle[i]) * f
        return Color(red: rgb.x, green: rgb.y, blue: rgb.z)
    }

    /// Confines the glow to the top of the screen: fully visible down to 25%
    /// of the height, gone by 50%. Below that the base colour shows through
    /// untouched, so the lower half is one flat tone.
    private var topFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0.0),
                .init(color: .white, location: 0.25),
                .init(color: .clear, location: 0.50),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension View {
    func fixFlyBackground(
        height: CGFloat = 440,
        startFade: CGFloat = 0.20,
        imageName: String = "fixfly_bg"
    ) -> some View {
        ZStack(alignment: .top) {
            FixFlyBackground(
                height: height,
                startFade: startFade,
                imageName: imageName
            )
            self
        }
    }
}
