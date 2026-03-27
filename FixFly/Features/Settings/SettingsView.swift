//
//  SettingsView.swift
//  FixFly
//
//  Created by Kanan Sultanov on 14.03.26.
//


import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Settings")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 42, height: 42)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                VStack(spacing: 12) {
                    settingsRow(title: "Device ID", icon: "iphone")
                    settingsRow(title: "Privacy Policy", icon: "lock.shield")
                    settingsRow(title: "Terms of Use", icon: "doc.text")
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func settingsRow(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
