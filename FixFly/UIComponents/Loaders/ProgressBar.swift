//
//  ProgressBar.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//

import SwiftUI

struct ProgressBar: View {
    var progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.15))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
            }
        }
    }
}
