import SwiftUI
import Combine

struct HeroHeaderRemote: View {
    let heroItems: [HeroMediaItemDTO]
    var onItemTap: ((HeroMediaItemDTO) -> Void)? = nil

    @State private var selectedIndex = 0
    @State private var dragX: CGFloat = 0
    
    private let timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    private let heroHeight: CGFloat = 300

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack(alignment: .bottom) {
                if !heroItems.isEmpty {
                    ZStack {
                        ForEach(Array(heroItems.enumerated()), id: \.element.id) { index, item in
                            HeroMediaPage(item: item)
                                .frame(width: width, height: heroHeight)
                                .clipped()
                                .offset(x: xOffset(for: index, width: width))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onItemTap?(item)
                                }
                        }
                    }

                    if heroItems.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(heroItems.indices, id: \.self) { index in
                                Capsule()
                                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.35))
                                    .frame(width: index == selectedIndex ? 18 : 7, height: 7)
                            }
                        }
                        .padding(.bottom, 14)
                    }
                }
            }
            .frame(width: width, height: heroHeight)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        guard abs(horizontal) > abs(vertical) else { return }
                        dragX = horizontal * 0.92
                    }
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        let predicted = value.predictedEndTranslation.width

                        guard abs(horizontal) > abs(vertical) else {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.92)) {
                                dragX = 0
                            }
                            return
                        }

                        let threshold = width * 0.24
                        var nextIndex = selectedIndex

                        if horizontal < -threshold || predicted < -threshold * 1.35 {
                            nextIndex = min(selectedIndex + 1, heroItems.count - 1)
                        } else if horizontal > threshold || predicted > threshold * 1.35 {
                            nextIndex = max(selectedIndex - 1, 0)
                        }

                        withAnimation(.spring(response: 0.42, dampingFraction: 0.90)) {
                            selectedIndex = nextIndex
                            dragX = 0
                        }
                    }
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.35),
                        Color.black.opacity(0.65),
                        Color.black
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            )
            .clipped()
        }
        .frame(height: heroHeight)
        .onReceive(timer) { _ in
            guard heroItems.count > 1, dragX == 0 else { return }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.90)) {
                selectedIndex = (selectedIndex + 1) % heroItems.count
            }
        }
    }

    private func xOffset(for index: Int, width: CGFloat) -> CGFloat {
        CGFloat(index - selectedIndex) * width + dragX
    }
}

private struct HeroMediaPage: View {
    let item: HeroMediaItemDTO

    var body: some View {
        ZStack {
            switch item.mediaType {
                
            case "video":
                if let url = URL(string: item.mediaUrl) {
                    LoopingVideoView(url: url, isActive: true)
                        .allowsHitTesting(false)
                } else {
                    fallback
                }

            case "image":
                if let url = URL(string: item.mediaUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Color.clear
                        }
                    }
                    .allowsHitTesting(false)
                } else {
                    fallback
                }
                
            default:
                fallback
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var fallback: some View {
        Color.clear
    }
}
