//
//  PhotoshootModels.swift
//  FixFly
//
//  The photoshoot feature: one selfie -> 5 cohesive photos in one style.
//  Catalog comes from GET /v1/photoshoot-templates.
//

import Foundation

struct PhotoshootCatalogResponse: Decodable {
    let cost: Int
    let templates: [PhotoshootTemplateDTO]
}

struct PhotoshootTemplateDTO: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let aspect: String
    /// The card image (the template's best example / anchor).
    let posterUrl: String
    /// The 5 example photos shown when the card is tapped.
    let examples: [String]
    let photoCount: Int
    let cost: Int
}
