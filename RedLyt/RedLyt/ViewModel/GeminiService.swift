//
//  GeminiService.swift
//  RedLyt
//
//  Created by Shahd Muharrq on 22/08/1447 AH.
//

import Foundation

enum GeminiError: Error {
    case invalidURL
    case badResponse
    case emptyResponse
    
}

final class GeminiService {
    
    private let apiKey = ApiKeys.gemini
    private let model = "gemini-1.5-flash"
    
    func generateReply(prompt: String) async throws -> String {
        guard let url = URL(string:
                                "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        ) else {
            throw GeminiError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = GeminiRequest(
            contents: [
                .init(
                    role: "user",
                    parts: [.init(text: prompt)]
                )
            ]
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: request)
        if let raw = String(data: data, encoding: .utf8) {
            print(" Gemini raw response:")
            print(raw)
        }
        
        guard let decoded = try? JSONDecoder().decode(GeminiResponse.self, from: data)
        else {
            throw GeminiError.badResponse
        }
        
        guard let candidate = decoded.candidates.first else {
            throw GeminiError.emptyResponse
        }
        
        let reply = candidate.content.parts
            .compactMap { $0.text }
            .joined()
        
        
        return reply
    }
}
