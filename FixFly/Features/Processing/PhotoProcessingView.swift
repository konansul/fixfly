//
//  PhotoProcessingView.swift
//  FixFly
//
//  Created by Kanan Sultanov on 27.03.26.
//

import SwiftUI
import Combine
import UserNotifications

struct PhotoProcessingView: View {
    @StateObject private var vm: PhotoProcessingViewModel
    @Environment(\.dismiss) private var dismiss
    
    var onComplete: ((String) -> Void)?
    
    // Анимации
    @State private var pulseState = false
    @State private var rotationState = 0.0
    
    private let fixFlyGradient = LinearGradient(
        colors: [
            Color(red: 0.55, green: 0.25, blue: 1.0),
            Color(red: 1.0, green: 0.35, blue: 0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    init(taskId: String, onComplete: ((String) -> Void)? = nil) {
        _vm = StateObject(wrappedValue: PhotoProcessingViewModel(taskId: taskId))
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            Color.clear.fixFlyBackground()
                .ignoresSafeArea()
            
            // Фоновое размытое свечение, которое пульсирует
            Circle()
                .fill(fixFlyGradient)
                .frame(width: 250, height: 250)
                .blur(radius: pulseState ? 80 : 40)
                .opacity(pulseState ? 0.3 : 0.1)
                .scaleEffect(pulseState ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseState)
            
            VStack(spacing: 0) {
                // Кнопка закрытия
                HStack {
                    Spacer()
//                    Button {
//                        dismiss()
//                    } label: {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 15, weight: .bold))
//                            .foregroundStyle(.white.opacity(0.7))
//                            .frame(width: 36, height: 36)
//                            .background(Color.white.opacity(0.1))
//                            .clipShape(Circle())
//                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Центральный блок с кольцом
                CircularProgressRing(
                    progress: vm.progressAmount,
                    remainingTime: vm.remainingTimeEstimate,
                    gradient: fixFlyGradient,
                    rotation: rotationState
                )
                
                Spacer()
                
                // Текстовый блок в красивой карточке
                VStack(spacing: 12) {
                    Text("FixFly AI is generating your masterpiece")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Feel free to close this screen.\nWe'll process it securely in the background.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Only offer the prompt while we can still ask. Once enabled
                // (or denied) the button is hidden — no pointless "Unsubscribe".
                if vm.notificationStatus == .notDetermined {
                    Button {
                        vm.requestNotificationPermission()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill")
                            Text("Notify Me When Ready")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            pulseState = true
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                rotationState = 360.0
            }
        }
        .task {
            await vm.startPollingStatus()
        }
        .onChange(of: vm.isProcessingComplete) { oldValue, completed in
            if completed {
                if let url = vm.outputUrl, let onComplete = onComplete {
                    onComplete(url)
                } else {
                    dismiss()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

private struct CircularProgressRing: View {
    let progress: Double
    let remainingTime: String
    let gradient: LinearGradient
    let rotation: Double

    var body: some View {
        ZStack {
//            // Внешнее тонкое вращающееся кольцо (Эффект загрузки)
//            Circle()
//                .trim(from: 0.1, to: 0.9)
//                .stroke(gradient.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 10]))
//                .frame(width: 260, height: 260)
//                .rotationEffect(.degrees(rotation))
//            
//            // Внешнее вращающееся кольцо 2 (в другую сторону)
//            Circle()
//                .trim(from: 0.2, to: 0.8)
//                .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 8]))
//                .frame(width: 240, height: 240)
//                .rotationEffect(.degrees(-rotation * 1.5))

            // Основной фон кольца
            Circle()
                .stroke(Color.black.opacity(0.5), lineWidth: 18)
                .frame(width: 200, height: 200)

            // Основной прогресс
            Circle()
                .trim(from: 0, to: max(0.01, progress)) // max нужен, чтобы точка была видна на 0%
                .stroke(gradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                .shadow(color: Color(red: 0.55, green: 0.25, blue: 1.0).opacity(0.6), radius: 10, x: 0, y: 0)

            // Текст внутри
            VStack(spacing: 8) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText()) // Плавная смена цифр (iOS 16+)
                
                VStack(spacing: 2) {
                    Text(remainingTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("estimated")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }
}
