//
//  DuoModels.swift
//  FixFly
//
//  The duo feature: TWO uploaded faces -> one video of them together (e.g. your
//  younger self + you today, hugging). Catalog comes from GET /v1/duo-templates.
//

import Foundation

struct DuoCatalogResponse: Decodable {
    let cost: Int
    let templates: [DuoTemplateDTO]
}

struct DuoTemplateDTO: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let aspect: String
    /// How many photos this template needs: 2 (compose two faces) or 1 (a photo
    /// that already has both people — animate the hug, keep the background).
    let uploads: Int
    /// Still shown on the card and as the detail hero fallback.
    let posterUrl: String
    /// Looping preview clip (the animated result look).
    let previewUrl: String
    /// Labels for the two upload slots (e.g. "Younger photo" / "Recent photo").
    let slot1Label: String
    let slot2Label: String
    let cost: Int

    /// Reuse the standard card views: the preview clip as a video card, the name as
    /// the title. Tapping still routes to DuoDetailView via the caller's NavigationLink.
    var cardItem: RemoteCardItem {
        .displayVideo(id: id, title: name, videoUrl: previewUrl)
    }
}
