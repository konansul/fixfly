import Foundation

struct HomeResponse: Decodable {
    let version: Int?
    let hero: HeroDTO
    let sections: [HomeSectionDTO]
}

struct HeroDTO: Decodable {
    let items: [HeroMediaItemDTO]
}

struct HeroMediaItemDTO: Codable, Identifiable, Hashable {
    let id: String
    let mediaType: String
    let mediaUrl: String
    let posterUrl: String?
    let action: HeroActionDTO?
    let resultType: String?
}

struct HeroActionDTO: Codable, Hashable {
    let type: String
    let targetId: String
}

struct HomeSectionDTO: Decodable, Identifiable {
    enum SectionType: String, Decodable {
        case carousel
        case carouselTabs
    }

    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let type: SectionType
    let items: [RemoteCardItem]?
    let tabs: [HomeTabDTO]?
    let action: HomeActionDTO?
}

struct HomeTabDTO: Decodable, Identifiable {
    let id: String
    let title: String
    let items: [RemoteCardItem]
}

struct RemoteCardItem: Decodable, Identifiable, Hashable {
    enum MediaType: String, Decodable {
        case image
        case video
    }

    let id: String
    let mediaType: MediaType
    let mediaUrl: String
    let posterUrl: String?
    let styleId: String?
    let prompt: String?
    let resultType: MediaType?

    var actualResultType: MediaType {
        return resultType ?? mediaType
    }
}

struct HomeActionDTO: Decodable {
    enum ActionType: String, Decodable {
        case navigate
    }

    let type: ActionType
    let target: String
    let payload: HomeActionPayloadDTO?
}

struct HomeActionPayloadDTO: Decodable {
    let title: String
    let endpoint: String
    let extra: [String: String]?
}

struct FeatureConfig: Identifiable, Hashable {
    let id = UUID()

    let title: String
    let placeholderText: String
    let processingTitle: String
    let processingSubtitle: String

    let endpointPath: String
    let extraFields: [String: String]
    let accepts: String

    init(
        title: String,
        endpointPath: String,
        extraFields: [String: String] = [:],
        accepts: String = "image/*",
        placeholderText: String = "Your result will appear here",
        processingTitle: String = "Processing…",
        processingSubtitle: String = "This usually takes a few seconds"
    ) {
        self.title = title
        self.endpointPath = endpointPath
        self.extraFields = extraFields
        self.accepts = accepts
        self.placeholderText = placeholderText
        self.processingTitle = processingTitle
        self.processingSubtitle = processingSubtitle
    }
}
