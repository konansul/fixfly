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

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected ? Color.white : Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}
