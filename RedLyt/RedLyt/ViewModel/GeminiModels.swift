//
//  GeminiModels.swift
//  RedLyt
//
//  Created by Shahd Muharrq on 22/08/1447 AH.
//

import Foundation

struct GeminiRequest: Encodable {
    struct Content: Encodable {
    struct Part: Encodable {
            let text: String
        }
        let role: String
        let parts: [Part]
    }
    
    let contents: [Content]
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
