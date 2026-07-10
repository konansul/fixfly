//
//  GuestBonusBanner.swift
//  FixFly
//
//  Persistent, dismissible reminder that signing in grants free coins. Shown to
//  guests on Home so the offer is always one tap away (the one-time pop-up can be
//  missed/dismissed). Tapping the banner triggers Sign in with Apple.
//

import SwiftUI

struct GuestBonusBanner: View {
    let coins: Int
    var onTap: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(FixFlyGradient.linear).frame(width: 40, height: 40)
                Image(systemName: "gift.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Get \(coins) free coins")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text("Sign in with Apple to claim")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer(minLength: 8)

            Text("Sign in")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(.white))
        }
        .padding(.leading, 12)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.10, green: 0.12, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(FixFlyGradient.linear, lineWidth: 1.2)
                        .opacity(0.55)
                )
        )
        .shadow(color: .black.opacity(0.45), radius: 16, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
            .buttonStyle(.plain)
            .offset(x: 5, y: -7)
        }
    }
}
