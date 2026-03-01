//
//  SpeechRecognizer.swift
//  RedLyt
//
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
    @Published var audioLevel: CGFloat = 0  // ← مستوى صوت الميكروفون الحي
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Silence detection
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 2.0
    
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
        
        // Stop any existing session first
        if audioEngine.isRunning {
            print("⚠️ Audio engine already running - stopping it first")
            stopListening()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actuallyStartListening()
            }
            return
        }
        
        actuallyStartListening()
    }
    
    private func actuallyStartListening() {
        // CRITICAL: Configure audio session for RECORDING
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Audio session set to RECORD mode")
        } catch {
            print("❌ Audio session setup failed: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                    print("📝 User said: \(self.transcript)")
                }
                
                self.resetSilenceTimer()
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                print("🛑 Recognition task ended")
                self.stopListening()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("❌ Invalid recording format: \(recordingFormat)")
            return
        }
        
        do {
            try inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self else { return }
                
                // إرسال البيانات للـ speech recognition
                self.recognitionRequest?.append(buffer)
                
                // ← حساب مستوى الصوت من الميكروفون
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                let rms = sqrt((0..<frameLength).map { pow(channelData[$0], 2) }.reduce(0, +) / Float(frameLength))
                let level = CGFloat(min(rms * 20, 1.0))
                
                DispatchQueue.main.async {
                    self.audioLevel = level
                }
            }
        } catch {
            print("❌ Failed to install audio tap: \(error)")
            return
        }
        
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
        
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        audioLevel = 0  // ← إعادة الخطوط للصفر عند التوقف
        
        // CRITICAL: Switch audio session back to PLAYBACK mode
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            print("✅ Audio session switched back to PLAYBACK mode")
        } catch {
            print("❌ Failed to switch audio session: \(error)")
        }
        
        // Small delay before notifying (gives audio session time to switch)
        let finalTranscript = transcript
        if !finalTranscript.isEmpty {
            print("✅ User finished speaking: '\(finalTranscript)'")
            // Delay callback slightly to ensure audio session is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.onUserFinishedSpeaking?(finalTranscript)
            }
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
