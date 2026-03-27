//
//  LedgerRowCard.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//

import SwiftUI

struct LedgerRowView: View {
    let item: WalletLedgerItem
    let formattedDate: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 42, height: 42)

                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))

                Text(formattedDate)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.50))
            }

            Spacer()

            Text(amountText)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(amountColor)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var amountText: String {
        item.amount > 0 ? "+\(item.amount)" : "\(item.amount)"
    }

    private var amountColor: Color {
        item.amount >= 0 ? .green : .white
    }

    private var iconName: String {
        switch item.reason.lowercased() {
        case "generation": return "sparkles"
        case "purchase": return "cart.fill"
        case "subscription": return "crown.fill"
        case "reward": return "gift.fill"
        default: return "bitcoinsign.circle.fill"
        }
    }

    private var iconBackground: Color {
        switch item.reason.lowercased() {
        case "generation": return .purple.opacity(0.35)
        case "purchase": return .blue.opacity(0.35)
        case "subscription": return .orange.opacity(0.35)
        case "reward": return .green.opacity(0.35)
        default: return .yellow.opacity(0.30)
        }
    }
}
