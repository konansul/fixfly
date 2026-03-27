//
//  FixFlyLoadingOverlay.swift
//  FixFly
//
//  Created by Kanan Sultanov on 17.03.26.
//


import SwiftUI

struct FixFlyLoadingOverlay: View {
    @State private var isSpinning = false
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Весь макет на светлом фоне приложения
            Color.clear.ignoresSafeArea()
            
            // 🔥 ОВЕРЛЕЙ: изолированный круг, перекрывающий только часть в центре 🔥
            ZStack {
                // Вращающееся градиентное кольцо
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.55, green: 0.25, blue: 1.0),
                                Color(red: 1.0, green: 0.35, blue: 0.85),
                                Color(red: 0.55, green: 0.25, blue: 1.0)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 84, height: 84) // 🔥 Увеличили размер кольца 🔥
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isSpinning)
                
                // 🔥 ЧЕРНЫЙ ФОН: Изолированный круг *внутри* кольца 🔥
                Circle()
                    .fill(.black.opacity(0.78)) // Заливаем черным
                    .frame(width: 68, height: 68) // Вписан внутрь кольца
                    .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 0) // Легкое свечение внутри
                
                // Твой логотип (буква F), наложенный поверх черного круга
                Image("fixfly")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    // Легкая пульсация размера
                    //.scaleEffect(isPulsing ? 1.05 : 0.9)
                   //bitcoin .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            }
            .contentShape(Circle())
            .background(
                Circle().fill(.black)
                    .frame(width: 84, height: 84)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10) // Тень от оверлея на фоне
        }
        .onAppear {
            // Запускаем анимации при появлении
            isSpinning = true
            isPulsing = true
        }
    }
}
