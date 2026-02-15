//
//  ApiKeys.swift
//  RedLyt
//

import Foundation
import SwiftUI

enum ApiKeys {
    static var openAI: String? {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = plist["OPEN_AI_API_KEY"] as? String,
            !key.isEmpty
        else {
            print("⚠️ Missing OPEN_AI_API_KEY in Config.plist")
            return nil
        }

        return key
    }
}
