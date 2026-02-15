import Foundation

enum OpenAIError: Error {
    case badURL
    case badResponse
    case empty
}

struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

final class OpenAIService {
    
    func generateReply(system: String, user: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw OpenAIError.badURL
        }
        
        let body: [String: Any] = [
            "model": "gpt-4.1-mini",
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "temperature": 0.7
        ]
        
        let json = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(ApiKeys.openAI)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let raw = String(data: data, encoding: .utf8) { print("OpenAI raw:", raw) }
            throw OpenAIError.badResponse
        }
        
        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content, !text.isEmpty else {
            throw OpenAIError.empty
        }
        return text
    }
}