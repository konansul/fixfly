//
//  ProButton.swift
//  FixFly
//
//  Created by Kanan Sultanov on 28.02.26.
//
import SwiftUI

struct ProButton: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "crown.fill")
                .font(.system(size: 13, weight: .semibold))
            Text("Pro")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.55, green: 0.25, blue: 1.0),
                        Color(red: 1.0, green: 0.35, blue: 0.85)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        )
    }
}
