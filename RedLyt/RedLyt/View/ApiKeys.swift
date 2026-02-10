//
//  ApiKeys.swift
//  RedLyt
//
//  Created by Shahd Muharrq on 22/08/1447 AH.
//

import Foundation


enum ApiKeys {
    static var gemini: String {
        
        guard
        let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
        let data = try? Data(contentsOf: url),
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
        let key = plist["API_KEY"] as? String
        else {
            fatalError("Missing API_KEY in Config.plist")
        }
        
        
        return key
        
    }
   
}


