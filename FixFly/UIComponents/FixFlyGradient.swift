//  FixFlyGradient.swift
//  FixFly
//
//  Brand colors — the exact saturated hues the animated FixFlyBackground
//  cycles through. Use for primary action buttons so they visually belong
//  to the same family as the background glow.
//

import SwiftUI

enum FixFlyGradient {
    static let blue = Color(red: 0.15, green: 0.35, blue: 0.98)
    static let pink = Color(red: 0.98, green: 0.20, blue: 0.68)
    static let purple = Color(red: 0.58, green: 0.18, blue: 0.98)

    /// Primary button gradient: blue → purple → pink, like the background.
    static let linear = LinearGradient(
        colors: [blue, purple, pink],
        startPoint: .leading,
        endPoint: .trailing
    )
}
