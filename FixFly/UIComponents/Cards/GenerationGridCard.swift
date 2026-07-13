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
        if item.isPhotoshoot {
            // Show it as a fanned stack so it's obvious this is a SET of photos.
            PhotoshootStackThumb(urls: item.displayUrls)
        } else {
            singleThumbnail
        }
    }

    private var singleThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)

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
                            MediaLoadingPlaceholder()
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

/// A miniature fanned stack for a photoshoot in the My Generations grid: two
/// frames peek out behind the first, so it reads as a SET, not one image.
struct PhotoshootStackThumb: View {
    let urls: [String]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cardW = w * 0.80
            let cardH = h * 0.86

            ZStack {
                frame(url: url(at: 2), w: cardW, h: cardH)
                    .scaleEffect(0.94)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -w * 0.075, y: h * 0.03)

                frame(url: url(at: 1), w: cardW, h: cardH)
                    .scaleEffect(0.97)
                    .rotationEffect(.degrees(5))
                    .offset(x: w * 0.075, y: h * 0.015)

                frame(url: url(at: 0), w: cardW, h: cardH)
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(0.75, contentMode: .fit)
    }

    private func url(at i: Int) -> String {
        urls.indices.contains(i) ? urls[i] : (urls.first ?? "")
    }

    private func frame(url: String, w: CGFloat, h: CGFloat) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                MediaLoadingPlaceholder()
            }
        }
        .frame(width: w, height: h)
        .clipped()
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 3)
    }
}
