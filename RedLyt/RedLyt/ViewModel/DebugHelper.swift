//
//  DebugHelper.swift
//  RedLyt
//
//  Created by Areeg Altaiyah on 15/02/2026.
//


//
//  DebugHelper.swift
//  RedLyt
//
//  Add this temporarily to debug the API key issue
//

import Foundation

struct DebugHelper {
    static func checkAPIKeyStatus() {
        print("=== API KEY DEBUG ===")
        
        // Check if Config.plist exists
        if let url = Bundle.main.url(forResource: "Config", withExtension: "plist") {
            print("✅ Config.plist found at: \(url)")
            
            // Try to load it
            if let data = try? Data(contentsOf: url) {
                print("✅ Config.plist loaded successfully")
                
                // Try to parse it
                if let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                    print("✅ Config.plist parsed successfully")
                    print("📋 Keys in plist: \(plist.keys)")
                    
                    // Check for API key
                    if let key = plist["OPEN_AI_API_KEY"] as? String {
                        if key.isEmpty {
                            print("❌ OPEN_AI_API_KEY is EMPTY")
                        } else {
                            let preview = String(key.prefix(10)) + "..."
                            print("✅ OPEN_AI_API_KEY found: \(preview)")
                            
                            // Check format
                            if key.hasPrefix("sk-") {
                                print("✅ API key format looks correct (starts with sk-)")
                            } else {
                                print("⚠️ API key doesn't start with 'sk-' - might be invalid")
                            }
                        }
                    } else {
                        print("❌ OPEN_AI_API_KEY not found in plist")
                    }
                } else {
                    print("❌ Failed to parse Config.plist")
                }
            } else {
                print("❌ Failed to load Config.plist")
            }
        } else {
            print("❌ Config.plist NOT FOUND in bundle")
            print("📍 Make sure you:")
            print("   1. Created Config.plist")
            print("   2. Added it to your app target")
            print("   3. Put it in the same folder as your Swift files")
        }
        
        print("===================")
    }
}