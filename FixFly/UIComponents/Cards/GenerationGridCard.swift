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
}

struct GenerationThumbnailView: View {
    let item: GenerationItemDTO

    private var isVideo: Bool {
        let outStr = item.outputUrl?.lowercased() ?? ""
        return outStr.hasSuffix(".mp4") || outStr.hasSuffix(".mov")
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))

            if let urlString = item.outputUrl, let url = URL(string: urlString) {
                if isVideo {
                    CachedVideoView(remoteURL: url)
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                        .overlay(alignment: .topLeading) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .padding(8)
                        }
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().tint(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 26))
                                .foregroundStyle(.white.opacity(0.45))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .aspectRatio(0.75, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}
