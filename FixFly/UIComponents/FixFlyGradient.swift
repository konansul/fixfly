//  FixFlyGradient.swift
//  FixFly
//
//  Brand colors — the light-blue / turquoise family from the app icon.
//  Use for primary action buttons, selected states and accents so everything
//  belongs to the same family as the animated FixFlyBackground glow.
//

import SwiftUI

enum FixFlyGradient {
    // New brand palette (matches the app icon): turquoise → sky → blue.
    // Names kept (blue/pink/purple) for source compatibility with existing
    // call sites; the *values* are now the blue/turquoise theme.
    static let blue = Color(red: 0.13, green: 0.45, blue: 0.97)    // deep blue
    static let pink = Color(red: 0.22, green: 0.86, blue: 0.97)    // turquoise / cyan
    static let purple = Color(red: 0.26, green: 0.64, blue: 0.99)  // sky blue

    /// Single solid accent for selected pills, focus borders, small accents.
    static let accent = Color(red: 0.22, green: 0.64, blue: 0.99)

    /// Primary gradient: turquoise → sky → blue (shimmering light blue).
    static let linear = LinearGradient(
        colors: [pink, purple, blue],
        startPoint: .leading,
        endPoint: .trailing
    )
}
