import Foundation

enum GeminiServiceError: Error {
    case badURL
    case badResponse
    case empty
}

struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

final class GeminiService {
    private let session: URLSession
    private let model: String

    init(session: URLSession = .shared, model: String = "gemini-1.5-flash") {
        self.session = session
        self.model = model
    }

    func generateReply(prompt: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(ApiKeys.gemini)") else {
            throw GeminiServiceError.badURL
        }

        // Minimal text-only request body
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        let json = try JSONSerialization.data(withJSONObject: body, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let raw = String(data: data, encoding: .utf8) {
                print("Gemini raw error:", raw)
            }
            throw GeminiServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)

        // Extract first text part
        if let text = decoded.candidates.first?.content.parts.first?.text, !text.isEmpty {
            return text
        }

        throw GeminiServiceError.empty
    }
}
