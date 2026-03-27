//  FixFlyBackground.swift
//  FixFlyBackground.swift
//  FixFly
//
//  Created by Kanan Sultanov on 12.03.26.
//

import SwiftUI

struct FixFlyBackground: View {
    var height: CGFloat = 260
    var startFade: CGFloat = 0.35
    var imageName: String = "fixfly_bg"

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea()

            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .clipped()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.00),
                            .init(color: .white, location: startFade),
                            .init(color: .white.opacity(0.90), location: 0.45),
                            .init(color: .white.opacity(0.70), location: 0.60),
                            .init(color: .white.opacity(0.45), location: 0.75),
                            .init(color: .white.opacity(0.20), location: 0.88),
                            .init(color: .clear, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .top)
        }
    }
}

extension View {
    func fixFlyBackground(
        height: CGFloat = 260,
        startFade: CGFloat = 0.35,
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
