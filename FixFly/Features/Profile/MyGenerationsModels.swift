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
        case costUserCoins = "cost_user_coins"
        case costApiCredits = "cost_api_credits"
        case requestMeta = "request_meta"
        case errorText = "error_text"
        case createdAt = "created_at"
    }
}

enum StringOrIntOrDoubleOrBool: Decodable, CustomStringConvertible, Hashable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    var description: String {
        switch self {
        case .string(let v): return v
        case .int(let v): return "\(v)"
        case .double(let v): return "\(v)"
        case .bool(let v): return v ? "true" : "false"
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

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported value type in requestMeta"
        )
    }
}

extension Notification.Name {
    static let generationNeedsRefresh = Notification.Name("generationNeedsRefresh")
}
