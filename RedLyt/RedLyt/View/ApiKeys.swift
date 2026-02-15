//
//  ApiKeys.swift
//  RedLyt
//
//  Created by Shahd Muharrq on 22/08/1447 AH.
//

import Foundation

enum ApiKeys {
    // Reads a string value for a given key from Config.plist in the main bundle.
    private static func value(for key: String) -> String {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String,
            !value.isEmpty
        else {
            fatalError("Missing \(key) in Config.plist")
        }
        return value
    }

    // Existing Gemini key (expects "API_KEY" in Config.plist)
    static var gemini: String {
        value(for: "API_KEY")
    }

    // OpenAI key (expects "OPENAI_API_KEY" in Config.plist)
    static var openAI: String {
        value(for: "OPENAI_API_KEY")
    }
}
