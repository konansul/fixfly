//
//  APIError.swift
//  FixFly
//

import Foundation

enum ErrorAPI: LocalizedError {
    case badURL
    case badResponse
    case unauthorized(String)
    case http(Int, String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Bad URL"

        case .badResponse:
            return "Bad server response"

        case .unauthorized(let message):
            return message.isEmpty ? "Unauthorized" : message

        case .http(let code, let message):
            return "HTTP \(code): \(message)"

        case .decoding:
            return "Failed to decode response"
        }
    }
}
