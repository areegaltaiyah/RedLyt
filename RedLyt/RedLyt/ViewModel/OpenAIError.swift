//
//  OpenAIService.swift
//  RedLyt
//

import Foundation

enum OpenAIError: Error {
    case badURL
    case badResponse
    case empty
    case missingAPIKey
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

    struct ConversationMessage {
        let role: String
        let content: String
    }

    func generateReply(
        system: String,
        conversationHistory: [Message],
        userMessage: String
    ) async throws -> String {
        
        // Check for API key
        guard let apiKey = ApiKeys.openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw OpenAIError.badURL
        }

        // Build messages array with conversation history
        var messages: [[String: String]] = [
            ["role": "system", "content": system]
        ]
        
        // Add conversation history
        for message in conversationHistory {
            messages.append([
                "role": message.role,
                "content": message.content
            ])
        }
        
        // Add new user message
        messages.append([
            "role": "user",
            "content": userMessage
        ])

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 150  // Keep responses short for driving
        ]

        let json = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            if let raw = String(data: data, encoding: .utf8) {
                print("OpenAI raw error:", raw)
            }
            throw OpenAIError.badResponse
        }

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content, !text.isEmpty else {
            throw OpenAIError.empty
        }
        return text
    }
}
