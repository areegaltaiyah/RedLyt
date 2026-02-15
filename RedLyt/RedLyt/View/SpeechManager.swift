//
//  SpeechManager.swift
//  RedLyt
//

import Foundation
import AVFoundation
import Combine

final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    private let synth = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    // Callback when AI finishes speaking
    var onFinishedSpeaking: (() -> Void)?
    
    // Track if speech was interrupted vs naturally finished
    private var wasInterrupted = false

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String, language: String = "en-US") {
        // CRITICAL: Set isSpeaking IMMEDIATELY, before doing anything else
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
        
        print("🔊 SpeechManager.speak() called with: '\(text)'")
        
        // Stop any existing speech
        if synth.isSpeaking {
            print("⚠️ Already speaking - stopping current speech")
            wasInterrupted = true  // Mark as interrupted
            synth.stopSpeaking(at: .immediate)
            // Give it a tiny moment to stop
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Configure audio session for playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            print("✅ Audio session configured for playback")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }

        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: language)
        u.rate = 0.48
        u.volume = 1.0
        
        wasInterrupted = false  // Reset interrupt flag
        synth.speak(u)
        print("🔊 Speech utterance queued")
    }
    
    func stop() {
        print("🛑 SpeechManager.stop() called")
        wasInterrupted = true  // Mark as interrupted
        synth.stopSpeaking(at: .immediate)
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🔊 Speech ACTUALLY started")
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ Speech finished (wasInterrupted: \(wasInterrupted))")
        
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
        
        // Only trigger callback if speech finished naturally (not interrupted)
        if !wasInterrupted {
            print("✅ Speech finished naturally - triggering callback")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.onFinishedSpeaking?()
            }
        } else {
            print("⏭️ Speech was interrupted - NOT triggering callback")
            wasInterrupted = false  // Reset for next time
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("❌ Speech was cancelled")
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
        wasInterrupted = false  // Reset
    }
}
