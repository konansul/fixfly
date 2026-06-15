//
//  TemplateVideoWall.swift
//  FixFly
//
//  Scrolling wall of 12 bundled template videos (onb_1…onb_12 data sets):
//  3 columns drifting up/down on a conveyor, so there are exactly 12 players
//  (no duplication — stays within iOS's simultaneous-decoder budget).
//  Behind the tiles is a subtle brand gradient that shows through the gaps.
//  Reused by Onboarding and the Paywall.
//

import SwiftUI
import UIKit
import AVFoundation

struct TemplateVideoWall: View {
    var body: some View {
        ZStack {
            // Brand-tinted dark backdrop, visible in the gaps between tiles.
            Color.black
            LinearGradient(
                colors: [
                    FixFlyGradient.blue.opacity(0.40),
                    .clear,
                    FixFlyGradient.pink.opacity(0.28),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                let spacing: CGFloat = 12
                let cols = 3
                let w = (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
                HStack(spacing: spacing) {
                    VideoMarqueeColumn(indices: [1, 4, 7, 10], movingUp: true,  tileWidth: w, viewHeight: geo.size.height)
                    VideoMarqueeColumn(indices: [2, 5, 8, 11], movingUp: false, tileWidth: w, viewHeight: geo.size.height)
                    VideoMarqueeColumn(indices: [3, 6, 9, 12], movingUp: true,  tileWidth: w, viewHeight: geo.size.height)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

/// One column: a fixed set of video tiles repositioned on a loop (conveyor),
/// so there are exactly `indices.count` players — no duplication.
private struct VideoMarqueeColumn: View {
    let indices: [Int]
    let movingUp: Bool
    let tileWidth: CGFloat
    let viewHeight: CGFloat

    private let spacing: CGFloat = 12
    private let speed: CGFloat = 26

    private var tileHeight: CGFloat { tileWidth * 1.8 }
    private var step: CGFloat { tileHeight + spacing }
    private var blockHeight: CGFloat { CGFloat(indices.count) * step }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
            let d = (t * speed).truncatingRemainder(dividingBy: blockHeight)

            ZStack(alignment: .top) {
                ForEach(Array(indices.enumerated()), id: \.element) { pos, idx in
                    let base = CGFloat(pos) * step
                    let raw = movingUp ? base - d : base + d
                    tile(idx).offset(y: wrap(raw) - tileHeight)
                }
            }
            .frame(width: tileWidth, height: viewHeight, alignment: .top)
            .clipped()
        }
        .frame(width: tileWidth, height: viewHeight)
        .clipped()
    }

    private func wrap(_ v: CGFloat) -> CGFloat {
        let m = v.truncatingRemainder(dividingBy: blockHeight)
        return m < 0 ? m + blockHeight : m
    }

    private func tile(_ idx: Int) -> some View {
        WallVideoTile(index: idx, width: tileWidth, height: tileHeight)
    }
}

/// One tile: loads its video off the main thread (so pushing the wall never
/// hangs while 12 clips are extracted) and shows a brand placeholder until ready.
private struct WallVideoTile: View {
    let index: Int
    let width: CGFloat
    let height: CGFloat

    @State private var url: URL?

    var body: some View {
        Group {
            if let url {
                LoopingCardVideoView(url: url, isMuted: true)
            } else {
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task {
            if url == nil { url = await TemplateWallVideo.url(for: index) }
        }
    }

    private var placeholder: some View {
        let pairs: [[Color]] = [
            [FixFlyGradient.blue, FixFlyGradient.purple],
            [FixFlyGradient.purple, FixFlyGradient.pink],
            [FixFlyGradient.pink, FixFlyGradient.blue],
        ]
        let p = pairs[index % pairs.count]
        return LinearGradient(colors: p.map { $0.opacity(0.7) },
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Materializes a bundled video data set (onb_N) to a temp file so AVPlayer can
/// play it from a URL. The heavy NSDataAsset read + disk write run OFF the main
/// thread; the file is cached on disk after the first time.
enum TemplateWallVideo {
    static func url(for index: Int) async -> URL? {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("onb_\(index).mp4")
        if FileManager.default.fileExists(atPath: tmp.path) {
            return tmp
        }
        return await Task.detached(priority: .userInitiated) {
            guard let data = NSDataAsset(name: "onb_\(index)")?.data else { return nil }
            do {
                try data.write(to: tmp)
                return tmp
            } catch {
                return nil
            }
        }.value
    }
}
