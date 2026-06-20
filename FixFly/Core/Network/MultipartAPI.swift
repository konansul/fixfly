import UIKit
import Foundation

final class MultipartAPI {
    static let shared = MultipartAPI()
    private init() {}

    func processImage(
        endpointPath: String,
        image: UIImage,
        extraFields: [String: String] = [:],
        accept: String = "image/*",
        requiresAuth: Bool = true
    ) async throws -> UIImage {
        let request = try createMultipartRequest(
            endpointPath: endpointPath,
            image: image,
            extraFields: extraFields,
            accept: accept,
            requiresAuth: requiresAuth
        )

        let (data, resp) = try await NetworkSession.upload.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw ErrorAPI.badResponse }

        guard (200...299).contains(http.statusCode) else {
            let message = Self.extractServerErrorMessage(from: data) ?? "Server error"
            if http.statusCode == 401 {
                throw ErrorAPI.unauthorized(message)
            }
            throw ErrorAPI.http(http.statusCode, message)
        }

        guard let img = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        return img
    }

    func processImageToVideo(
        endpointPath: String,
        image: UIImage,
        extraFields: [String: String] = [:],
        accept: String = "video/mp4",
        requiresAuth: Bool = true
    ) async throws -> URL {
        let request = try createMultipartRequest(
            endpointPath: endpointPath,
            image: image,
            extraFields: extraFields,
            accept: accept,
            requiresAuth: requiresAuth
        )

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)

        let (data, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw ErrorAPI.badResponse }

        guard (200...299).contains(http.statusCode) else {
            let message = Self.extractServerErrorMessage(from: data) ?? "Server error"
            if http.statusCode == 401 {
                throw ErrorAPI.unauthorized(message)
            }
            throw ErrorAPI.http(http.statusCode, message)
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".mp4"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            throw URLError(.cannotCreateFile)
        }
    }

    func startBackgroundGeneration(
        endpointPath: String,
        images: [UIImage] = [],
        extraFields: [String: String] = [:],
        requiresAuth: Bool = true
    ) async throws -> String {
        
        guard let url = URL(string: ConfigAPI.baseURL + endpointPath) else {
            throw ErrorAPI.badURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if requiresAuth {
            guard let token = TokenStore.shared.accessToken, !token.isEmpty else {
                throw ErrorAPI.unauthorized("No access token. Please login first.")
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        
        for (key, value) in extraFields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        for (index, image) in images.enumerated() {
            if let jpeg = Self.uploadJPEG(from: image) {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"files\"; filename=\"photo\(index).jpg\"\r\n")
                body.append("Content-Type: image/jpeg\r\n\r\n")
                body.append(jpeg)
                body.append("\r\n")
            }
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, resp) = try await NetworkSession.upload.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw ErrorAPI.badResponse }
        
        guard (200...299).contains(http.statusCode) else {
            let message = Self.extractServerErrorMessage(from: data) ?? "Server error"
            if http.statusCode == 401 {
                throw ErrorAPI.unauthorized(message)
            }
            throw ErrorAPI.http(http.statusCode, message)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let taskId = json["task_id"] as? String else {
            throw ErrorAPI.badResponse
        }
        
        return taskId
    }

    private func createMultipartRequest(
        endpointPath: String,
        image: UIImage,
        extraFields: [String: String],
        accept: String,
        requiresAuth: Bool
    ) throws -> URLRequest {
        
        guard let url = URL(string: ConfigAPI.baseURL + endpointPath) else {
            throw ErrorAPI.badURL
        }

        guard let jpeg = Self.uploadJPEG(from: image) else {
            throw ErrorAPI.badResponse
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(accept, forHTTPHeaderField: "Accept")

        if requiresAuth {
            guard let token = TokenStore.shared.accessToken, !token.isEmpty else {
                throw ErrorAPI.unauthorized("No access token. Please login first.")
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        for (key, value) in extraFields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(jpeg)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body
        return request
    }

    /// JPEG bytes for upload. Full-resolution camera/library photos are several
    /// MB, which stalls uploads on a weak connection. The generation models
    /// don't need more than ~1536px on the long edge, so we downscale first and
    /// use a slightly lower quality — typically cutting the payload several-fold
    /// with no visible loss in the result.
    private static func uploadJPEG(
        from image: UIImage,
        maxDimension: CGFloat = 1536,
        quality: CGFloat = 0.8
    ) -> Data? {
        image.downscaled(maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    private static func extractServerErrorMessage(from data: Data) -> String? {
        if
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let detail = obj["detail"]
        {
            if let s = detail as? String { return s }
            if let arr = detail as? [Any] { return String(describing: arr) }
            if let dict = detail as? [String: Any] { return String(describing: dict) }
            return String(describing: detail)
        }

        let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (text?.isEmpty == false) ? text : nil
    }
}

private extension Data {
    mutating func append(_ string: String) {
        self.append(string.data(using: .utf8)!)
    }
}

private extension UIImage {
    /// Returns a copy scaled so its longest edge is at most `maxDimension`
    /// points (rendered at scale 1, so points == pixels). Smaller images are
    /// returned unchanged. Used to shrink uploads.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }

        let ratio = maxDimension / longest
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
