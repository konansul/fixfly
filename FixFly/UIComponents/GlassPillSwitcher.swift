//  GlassPillSwitcher.swift
//  FixFly
//
//  Segmented pill switcher with a sliding Liquid Glass knob on iOS 26+,
//  falling back to a translucent capsule on iOS 18. Used by the paywall
//  (Subscription / Coins) and the Library (Photo / Video).
//

import SwiftUI

struct GlassPillSwitcher: View {
    let options: [String]
    @Binding var selectedIndex: Int
    var height: CGFloat = 52

    var body: some View {
        ZStack {
            // Sliding knob under the selected segment.
            GeometryReader { geo in
                let segmentWidth = geo.size.width / CGFloat(options.count)
                knobBackground
                    .frame(width: segmentWidth - 8, height: geo.size.height - 8)
                    .offset(x: segmentWidth * CGFloat(selectedIndex) + 4, y: 4)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: selectedIndex)
            }

            HStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { index in
                    Button {
                        guard index != selectedIndex else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedIndex = index
                    } label: {
                        Text(options[index])
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(index == selectedIndex ? 1.0 : 0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: height)
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: selectedIndex)
        }
        .frame(height: height)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    @ViewBuilder
    private var knobBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            Capsule()
                .fill(Color.white.opacity(0.16))
        }
    }
}
