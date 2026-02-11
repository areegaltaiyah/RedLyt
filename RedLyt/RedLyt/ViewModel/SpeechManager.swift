//
//  SpeechManager.swift
//  RedLyt
//  FIXED: Added proper audio session configuration
//

import Foundation
import AVFoundation

final class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {

    private let synthesizer = AVSpeechSynthesizer()

    var onSpeechFinished: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession() // NEW: Setup audio session
    }

    // NEW: Configure audio session for speech playback
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Set category to playback so audio works even when device is on silent mode
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            
            // Activate the audio session
            try audioSession.setActive(true)
            
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }

    func speak(_ text: String, language: String = "en-US") {
        print("🔊 Attempting to speak: \(text.prefix(50))...")
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            print("⏹️ Stopping current speech")
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Ensure audio session is active
        configureAudioSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)

        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        print("🎤 Starting speech synthesis...")
        synthesizer.speak(utterance)
    }

    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didStart utterance: AVSpeechUtterance) {
        print("🗣️ Speech started")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        print("✅ Speech finished")
        onSpeechFinished?()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        print("⚠️ Speech was cancelled")
    }
}
