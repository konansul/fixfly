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

/// One choice of a parametrised template — e.g. a national team in Fan Cam.
/// Each variant ships its own finished prompt, so the app never substitutes
/// placeholders itself.
struct TemplateVariant: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    /// An emoji: a flag for Fan Cam's countries, a dancer for the dances.
    let flag: String
    /// Absent for dances — there the driving clip is the instruction, and the
    /// backend resolves it from `id` alone.
    let prompt: String?
}

/// A short piece of text the user types before generating — e.g. the slogan on the
/// flag in Skyline Dare. It replaces `{key}` inside `stillPromptTemplate`.
/// Kept short on purpose: image models render two or three capitalised words
/// perfectly and smear whole sentences.
struct TemplateInput: Decodable, Identifiable, Hashable {
    var id: String { key }
    let key: String
    let label: String
    let placeholder: String
    let maxLength: Int
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
    /// Example input face shown as "your face → result" in the template detail.
    /// Present for both photos and videos (posterUrl stays the feed thumbnail).
    let modelUrl: String?
    let styleId: String?
    let prompt: String?
    let resultType: MediaType?
    /// Recently added — shown first in Library with a "NEW" badge.
    let isNew: Bool?
    /// Present when the user must pick something (a country, a team…) before
    /// uploading. `prompt` above stays a working default for older builds.
    let variants: [TemplateVariant]?
    /// Baked into the card rather than picked: a dance template names its driving
    /// clip here, and the backend resolves the clip from this id alone.
    let variant: String?
    /// The scene is composed for a fixed ratio, so the uploaded photo's own
    /// orientation must not decide the output (see TemplateFeedView).
    let forceAspectRatio: String?

    /// Two-step templates: the opening frame is drawn from this, then animated by
    /// `prompt`. Sent to the backend as `still_prompt`; when absent the template is
    /// an ordinary one-step generation.
    let stillPrompt: String?
    /// The same, still carrying `{KEY}` placeholders for `inputs` to fill.
    let stillPromptTemplate: String?
    /// Short text the user types in before generating.
    let inputs: [TemplateInput]?

    /// Which provider processes this template's photo. Sent by the backend because
    /// it cannot be inferred from the media type: the dance templates are Kling
    /// (Kuaishou), not Google, and the data-use chip has to say so.
    let engine: String?
    /// Motion-control templates need the whole body in frame; the app explains that
    /// before it opens the picker.
    let requiresFullBody: Bool?

    var actualResultType: MediaType {
        return resultType ?? mediaType
    }

    var provider: AIProvider {
        AIProvider(rawValue: engine ?? "") ?? (actualResultType == .video ? .veo : .gemini)
    }

    var needsFullBodyPhoto: Bool { requiresFullBody == true }
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
