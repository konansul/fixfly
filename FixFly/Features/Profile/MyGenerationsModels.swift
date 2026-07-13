import Foundation

struct MyGenerationsResponse: Decodable {
    let items: [GenerationItemDTO]
}

struct GenerationItemDTO: Decodable, Identifiable, Hashable, Equatable {
    let id: String
    let featureKey: String
    let status: String
    let inputUrl: String?
    let outputUrl: String?
    /// A photoshoot returns 5 files here; single-output features leave it nil.
    let outputUrls: [String]?
    let costUserCoins: Int?
    let costApiCredits: Int?
    let requestMeta: [String: StringOrIntOrDoubleOrBool]?
    let errorText: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case featureKey = "feature_key"
        case status
        case inputUrl = "input_url"
        case outputUrl = "output_url"
        case outputUrls = "outputs"
        case costUserCoins = "cost_user_coins"
        case costApiCredits = "cost_api_credits"
        case requestMeta = "request_meta"
        case errorText = "error_text"
        case createdAt = "created_at"
    }

    var isPhotoshoot: Bool { featureKey == "photoshoot" }

    /// The photos to display: the full set for a photoshoot, otherwise the single
    /// output. Falls back to the anchor (`outputUrl`) if `outputs` is missing.
    var displayUrls: [String] {
        if let urls = outputUrls, !urls.isEmpty { return urls }
        if let out = outputUrl { return [out] }
        return []
    }
}

enum StringOrIntOrDoubleOrBool: Decodable, CustomStringConvertible, Hashable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    /// request_meta can now hold arrays too (e.g. a photoshoot's `outputs`). Without
    /// this case the decoder threw on the array and the WHOLE list failed to load.
    case strings([String])

    var description: String {
        switch self {
        case .string(let v): return v
        case .int(let v): return "\(v)"
        case .double(let v): return "\(v)"
        case .bool(let v): return v ? "true" : "false"
        case .strings(let v): return v.joined(separator: ", ")
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        if let value = try? container.decode([String].self) {
            self = .strings(value)
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported value type in requestMeta"
        )
    }
}

extension Notification.Name {
    static let generationNeedsRefresh = Notification.Name("generationNeedsRefresh")
}
