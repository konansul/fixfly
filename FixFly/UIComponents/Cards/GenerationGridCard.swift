//
//  GenerationGridCard.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//

import SwiftUI

struct GenerationGridCard: View {
    let item: GenerationItemDTO
    let formattedDate: String
    let featureTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            GenerationThumbnailView(item: item)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(featureTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    // Spacer()

                    // statusChip(item.status)
                }

                Text(formattedDate)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)

                if let coins = item.costUserCoins {
                    Text("\(coins) coins")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func statusChip(_ status: String) -> some View {
        Text(status.capitalized)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(Color.white.opacity(0.12))
            )
    }
}

struct GenerationThumbnailView: View {
    let item: GenerationItemDTO

    // Проверяем, является ли результат видео
    private var isVideo: Bool {
        let outStr = item.outputUrl?.lowercased() ?? ""
        return outStr.hasSuffix(".mp4") || outStr.hasSuffix(".mov")
    }

    // 🔥 Если это видео, берем входную фотку. Если фото - берем готовый результат.
    private var imageURLToLoad: String? {
        if isVideo {
            return item.inputUrl
        }
        return item.outputUrl
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))

            if let urlString = imageURLToLoad, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)

                    case .success(let image):
                        ZStack {
                            image
                                .resizable()
                                .scaledToFit() // Измени на .scaledToFill() если хочешь, чтобы фотка заполняла всю карточку
                                .frame(maxWidth: .infinity, maxHeight: 210)
                                .padding(isVideo ? 0 : 8) // Убираем паддинг для видео-превью, чтобы было сочнее
                                .clipped()

                            // 🔥 Добавляем иконку "Play", чтобы было понятно, что это видео
                            if isVideo {
                                Color.black.opacity(0.2) // Легкое затемнение
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .shadow(radius: 4)
                            }
                        }

                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.45))

                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(height: 210)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}
