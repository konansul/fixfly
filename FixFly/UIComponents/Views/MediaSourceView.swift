//
//  MediaSourceView.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//



import SwiftUI

enum MediaSource {
    case image(UIImage)
    case remote(String)
}

struct SourceImageView: View {
    let source: MediaSource

    var body: some View {
        switch source {
        case .image(let image):
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)

        case .remote(let raw):
            if let url = makeURL(raw) {
                AsyncImage(url: url) { phase in
                    switch phase {

                    case .empty:
                        ZStack {
                            Color.white.opacity(0.05)
                            ProgressView().tint(.white)
                        }

                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                    case .failure:
                        errorPlaceholder

                    @unknown default:
                        errorPlaceholder
                    }
                }
                .id(url)
            } else {
                errorPlaceholder
            }
        }
    }
    
    private var errorPlaceholder: some View {
        ZStack {
            Color.white.opacity(0.05)
            Image(systemName: "photo")
                .font(.system(size: 26))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private func makeURL(_ raw: String) -> URL? {
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            return URL(string: raw)
        }
        return URL(string: ConfigAPI.baseURL + raw)
    }
}

struct ZoomableSourceImageView: View {
    let source: MediaSource
    @Binding var zoom: CGFloat
    @Binding var lastZoom: CGFloat

    var body: some View {
        SourceImageView(source: source)
            .scaleEffect(zoom)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let next = lastZoom * value
                        zoom = min(max(next, 1.0), 4.0)
                    }
                    .onEnded { _ in
                        lastZoom = zoom
                    }
            )
    }
}
