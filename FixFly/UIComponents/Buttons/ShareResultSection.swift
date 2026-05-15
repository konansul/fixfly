import SwiftUI

enum SharePlatform {
    case tiktok
    case youtube
    case instagram
    case whatsapp
}

struct ShareResultSection: View {
    let onDownloadTap: () -> Void
    let onShareTap: (SharePlatform) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Share to")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))

            HStack(spacing: 0) {
                Spacer(minLength: 0)

                shareSystemButton(systemName: "square.and.arrow.down", title: "Download", iconSize: 32, action: onDownloadTap)
                
                Spacer(minLength: 0)
                
                shareAssetButton(iconName: "ic_tiktok", title: "TikTok", iconSize: 44) {
                    onShareTap(.tiktok)
                }
                
                Spacer(minLength: 0)
                
                shareAssetButton(iconName: "ic_youtube", title: "YouTube", iconSize: 44) {
                    onShareTap(.youtube)
                }
                
                Spacer(minLength: 0)
                
                shareAssetButton(iconName: "ic_instagram", title: "Instagram", iconSize: 54) {
                    onShareTap(.instagram)
                }
                
                Spacer(minLength: 0)
                
                shareAssetButton(iconName: "ic_whatsapp", title: "WhatsApp", iconSize: 70) {
                    onShareTap(.whatsapp)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func shareAssetButton(iconName: String, title: String, iconSize: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .frame(width: 50, height: 50)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .frame(width: 65)
        }
        .buttonStyle(.plain)
    }

    private func shareSystemButton(systemName: String, title: String, iconSize: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
            .frame(width: 65)
        }
        .buttonStyle(.plain)
    }
}
