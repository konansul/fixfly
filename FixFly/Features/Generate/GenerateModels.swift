//
//  GenerateModels.swift
//  FixFly
//
//  Created by Kanan Sultanov on 21.03.26.
//

import SwiftUI

enum GenerationMediaType: String, CaseIterable, Identifiable {
    case image = "Photo"
    case video = "Video"
    case music = "Music"
    var id: String { self.rawValue }
}

struct GenerationOption: Identifiable {
    let id = UUID()
    let type: GenerationMediaType
    let title: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
}
