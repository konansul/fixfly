//  FixFlyBackground.swift
//  FixFly
//
//  Created by Kanan Sultanov on 12.03.26.
//
//  Animated, Gemini-style mesh gradient. A coloured glow sits at the top and
//  fades into TRUE black, then stays flat black for the rest of the screen.
//
//  The whole screen is ONE mesh — there is no clipped frame and no separate
//  black layer underneath. That matters: a clipped mesh's bottom edge is a
//  slightly-lifted "near black" (GPU interpolates in linear space), and where
//  that meets a real `Color.black` you get a visible horizontal seam, very
//  noticeable on OLED. By letting the mesh itself reach pure black across two
//  bottom rows, the lower half is a single uniform black with no seam.
//

import SwiftUI

struct FixFlyBackground: View {
    // Kept for source compatibility with existing call sites. No longer used —
    // the glow is now shaped by the mesh itself, full-screen.
    var height: CGFloat = 440
    var startFade: CGFloat = 0.20
    var imageName: String = "fixfly_bg"

    var body: some View {
        AnimatedMeshBackground()
            .ignoresSafeArea()
    }
}

// MARK: - Animated mesh gradient

/// A 3×4 `MeshGradient` filling the whole screen. The top carries the colour
/// glow which fades into a single MUTED dark tone by ~40% of the height, and
/// that same muted tone fills the rest of the screen. It is NOT pure black and
/// NOT a separate layer — it is two bottom rows of the same mesh, so the lower
/// region is one uniform tone with no seam to perceive. Control points and
/// colours animate slowly so the glow keeps morphing like a video.
private struct AnimatedMeshBackground: View {

    /// The "black" of the app: a muted near-black, never true `(0,0,0)`.
    /// Both bottom rows use this exact value, so the whole lower area is flat
    /// and identical — no seam, no OLED-true-black edge.
    private static let mutedDark = SIMD3<Float>(0.008, 0.008, 0.012)

    // 12 colours, row-major (3 wide × 4 tall).
    // Rows 0–1: glow. Rows 2–3: the muted dark tone.
    private let paletteA: [SIMD3<Float>] = [
        // row 0 (top) — glow
        SIMD3<Float>(0.10, 0.18, 0.45),   // blue
        SIMD3<Float>(0.26, 0.10, 0.46),   // purple
        SIMD3<Float>(0.42, 0.12, 0.38),   // magenta
        // row 1
        SIMD3<Float>(0.11, 0.24, 0.46),   // blue
        SIMD3<Float>(0.28, 0.12, 0.46),   // violet
        SIMD3<Float>(0.08, 0.33, 0.40),   // teal
        // row 2 (muted dark — fade completes here)
        mutedDark, mutedDark, mutedDark,
        // row 3 (same muted dark)
        mutedDark, mutedDark, mutedDark
    ]
    private let paletteB: [SIMD3<Float>] = [
        // row 0
        SIMD3<Float>(0.26, 0.10, 0.46),   // purple
        SIMD3<Float>(0.42, 0.12, 0.38),   // magenta
        SIMD3<Float>(0.08, 0.33, 0.40),   // teal
        // row 1
        SIMD3<Float>(0.28, 0.12, 0.46),   // violet
        SIMD3<Float>(0.10, 0.18, 0.45),   // blue
        SIMD3<Float>(0.26, 0.10, 0.46),   // purple
        // row 2 (muted dark)
        mutedDark, mutedDark, mutedDark,
        // row 3 (muted dark)
        mutedDark, mutedDark, mutedDark
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = Float(timeline.date.timeIntervalSinceReferenceDate)
            MeshGradient(
                width: 3,
                height: 4,
                points: points(at: t),
                colors: colors(at: t),
                smoothsColors: true
            )
        }
    }

    /// Per-cell crossfade between the two palettes. Muted-dark cells stay muted
    /// dark, so the lower half never lights up.
    private func colors(at t: Float) -> [Color] {
        (0..<12).map { i in
            let phase = Float(i) * 0.8
            let m = (sin(t * 0.45 + phase) + 1) / 2   // 0…1
            let a = paletteA[i]
            let b = paletteB[i]
            let c = a + (b - a) * m
            return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
        }
    }

    /// Outer corners are pinned and the side columns keep x = 0 / x = 1 so the
    /// rectangle is always fully filled. Only mid-column points drift, plus a
    /// little vertical breathing on the colour band (row 1). Rows 2–3 are fixed.
    private func points(at t: Float) -> [SIMD2<Float>] {
        let a: Float = 0.12   // horizontal drift of mid-column points
        func osc(_ freq: Float, _ phase: Float) -> Float { sin(t * freq + phase) }

        let y1: Float = 0.16   // colour band
        let y2: Float = 0.40   // muted dark starts here (and stays so below)

        return [
            // row 0 (y = 0)
            SIMD2<Float>(0, 0),
            SIMD2<Float>(0.5 + a * osc(0.45, 0.0), 0.0),
            SIMD2<Float>(1, 0),
            // row 1 (colour band, gentle drift + breathing)
            SIMD2<Float>(0.0, y1),
            SIMD2<Float>(0.5 + a * osc(0.40, 2.0), y1 + 0.04 * osc(0.30, 1.0)),
            SIMD2<Float>(1.0, y1),
            // row 2 (muted dark, fixed)
            SIMD2<Float>(0.0, y2),
            SIMD2<Float>(0.5, y2),
            SIMD2<Float>(1.0, y2),
            // row 3 (y = 1, muted dark, fixed)
            SIMD2<Float>(0, 1),
            SIMD2<Float>(0.5, 1),
            SIMD2<Float>(1, 1)
        ]
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
