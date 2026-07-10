//
//  FullBodyPhotoSheet.swift
//  FixFly
//
//  Shown once, right before the photo picker, for templates that copy a dancer's
//  movement onto the user (`requiresFullBody` in the template payload).
//
//  It exists because those templates fail loudly and expensively on the wrong
//  photo: a waist-up selfie makes Kling invent the legs, and anything held in the
//  hands is shredded into a blur. Either way the user has already paid 600 coins.
//  Pet templates do not get this sheet — they run on Veo from an ordinary snapshot.
//

import SwiftUI

struct FullBodyPhotoSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// Arms the picker. The parent opens it in this sheet's `onDismiss`, because
    /// presenting a second sheet mid-dismissal makes SwiftUI drop it.
    var onContinue: () -> Void

    private struct Rule: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let text: String
    }

    private let rules: [Rule] = [
        Rule(icon: "figure.stand",
             title: "Your whole body",
             text: "Head to feet, standing. A waist-up photo makes the dancer's legs get invented."),
        Rule(icon: "hand.raised",
             title: "Nothing in your hands",
             text: "Bags, phones and drinks smear as the arms move. Let them hang free."),
        Rule(icon: "person",
             title: "Just you",
             text: "One person in frame. With two, the dance can land on the wrong one."),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.fixFlyBackground()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            header

                            examples

                            ForEach(rules) { rule in
                                card(icon: rule.icon, title: rule.title, text: rule.text)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }

                    Button {
                        onContinue()
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(FixFlyGradient.linear)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Before you pick a photo")
            .navigationBarTitleDisplayMode(.inline)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This one copies a real dance onto you")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("It only works from the right kind of photo. Three things matter.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    /// The rules read as abstractions until you see the two photos side by side.
    /// Both are the same person, so the only difference on screen is the framing.
    private var examples: some View {
        HStack(spacing: 12) {
            example(image: "guide_fullbody", caption: "Full body", ok: true)
            example(image: "guide_faceonly", caption: "Face only", ok: false)
        }
    }

    private func example(image: String, caption: String, ok: Bool) -> some View {
        VStack(spacing: 8) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, ok ? .green : .red)
                        .padding(8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ok ? Color.green.opacity(0.7) : Color.red.opacity(0.7),
                                lineWidth: 2)
                )

            Text(caption)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ok ? .green : .red)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ok ? "Good example: full body" : "Bad example: face only")
    }

    private func card(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}
