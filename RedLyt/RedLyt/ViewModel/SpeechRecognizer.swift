//
//  SpeechRecognizer.swift
//  RedLyt
//  Handles listening to user speech and detecting when they stop talking
//

import Foundation
import Speech
import AVFoundation
import Combine

final class SpeechRecognizer: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var transcript: String = ""
    @Published var isListening: Bool = false
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Silence detection
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 2.0 // Stop after 2 seconds of silence
    
    // Callbacks
    var onUserFinishedSpeaking: ((String) -> Void)?
    
    // MARK: - Initialization
    override init() {
        super.init()
        requestAuthorization()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("✅ Speech recognition authorized")
                case .denied:
                    print("❌ Speech recognition denied")
                case .restricted:
                    print("❌ Speech recognition restricted")
                case .notDetermined:
                    print("⚠️ Speech recognition not determined")
                @unknown default:
                    print("❌ Unknown speech recognition status")
                }
            }
        }
    }
    
    // MARK: - Start Listening
    func startListening() {
        print("🎤 Starting to listen...")
        
        // Stop any existing session
        stopListening()
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get the audio input node
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                // Update transcript
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                    print("📝 User said: \(self.transcript)")
                }
                
                // Reset silence timer - user is speaking
                self.resetSilenceTimer()
                
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                print("🛑 Recognition task ended")
                self.stopListening()
            }
        }
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isListening = true
            transcript = ""
            print("✅ Audio engine started - listening for speech")
        } catch {
            print("❌ Audio engine failed to start: \(error)")
        }
    }
    
    // MARK: - Stop Listening
    func stopListening() {
        print("🛑 Stopping listening...")
        
        // Cancel silence timer
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End recognition
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        
        // Notify that user finished speaking
        if !transcript.isEmpty {
            print("✅ User finished speaking: '\(transcript)'")
            onUserFinishedSpeaking?(transcript)
        }
    }
    
    // MARK: - Silence Detection
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            print("🤐 Silence detected - user stopped talking")
            self?.stopListening()
        }
    }
}
