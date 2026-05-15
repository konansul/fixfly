import SwiftUI

struct LedgerRowView: View {
    let item: WalletLedgerItem
    let formattedDate: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            // Иконка транзакции
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
        let reason = item.reason.lowercased()
        
        if item.amount > 0 {
            return "bitcoinsign.circle.fill"
        }
        
        switch reason {
        case "veo_generation_start":
            return "video.fill"
        case "generation":
            return "photo.fill"
        case "purchase":
            return "cart.fill"
        case "subscription":
            return "crown.fill"
        case "reward":
            return "gift.fill"
        default:
            return "sparkles"
        }
    }

    private var iconBackground: Color {
        let reason = item.reason.lowercased()
        
        if item.amount > 0 {
            return .yellow.opacity(0.30)
        }
        
        switch reason {
        case "veo_generation_start":
            return .blue.opacity(0.35)
        case "generation":
            return .purple.opacity(0.35)
        case "purchase":
            return .orange.opacity(0.35)
        default:
            return .white.opacity(0.15)
        }
    }
}
