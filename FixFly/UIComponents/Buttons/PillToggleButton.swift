//
//  PillToggleButton.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//

import SwiftUI

struct PillToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    // Matches the Generate Video style chips (cinematic / anime / cyberpunk):
    // accent gradient when selected, faint white when not — not a solid white pill.
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(isSelected ? FixFlyGradient.accent : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }
}
