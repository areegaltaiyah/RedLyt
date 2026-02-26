//
//  SpeechManager.swift
//  RedLyt
//

import Foundation
import AVFoundation
import Combine

final class SpeechManager: NSObject, ObservableObject {

    // MARK: - Config
    private let voice = "nova"      // Options: alloy, echo, fable, onyx, nova, shimmer
    private let model = "tts-1" // Use "tts-1" to halve cost, quality is still great

    // MARK: - State
    @Published var isSpeaking = false

    /// Called when the AI finishes speaking naturally (not when stopped manually)
    var onFinishedSpeaking: (() -> Void)?

    // MARK: - Private
    private var audioPlayer: AVAudioPlayer?
    private var wasStopped = false
    private var currentTask: URLSessionDataTask?

    // MARK: - Public API

    func speak(_ text: String) {
        // Stop any current audio WITHOUT marking wasStopped = true
        stopCurrentAudio()

        // Now reset the flag so new speech can complete normally
        wasStopped = false

        guard let apiKey = ApiKeys.openAI else {
            print("❌ SpeechManager: missing OpenAI API key, aborting TTS")
            return
        }

        DispatchQueue.main.async { self.isSpeaking = true }
        print("🔊 SpeechManager: requesting TTS for '\(text.prefix(60))...'")

        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "input": text,
            "voice": voice,
            "response_format": "mp3"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                print("❌ OpenAI TTS error: \(error)")
                DispatchQueue.main.async { self.isSpeaking = false }
                return
            }

            guard let data, !data.isEmpty else {
                print("❌ OpenAI TTS: empty response")
                DispatchQueue.main.async { self.isSpeaking = false }
                return
            }

            guard !self.wasStopped else {
                print("⏭️ SpeechManager: stopped before audio arrived, skipping playback")
                DispatchQueue.main.async { self.isSpeaking = false }
                return
            }

            self.playAudio(data: data)
        }

        currentTask?.resume()
    }

    func stop() {
        print("🛑 SpeechManager: stopped by user")
        wasStopped = true
        stopCurrentAudio()
        DispatchQueue.main.async { self.isSpeaking = false }
    }

    // MARK: - Private

    /// Stops any in-flight request and audio WITHOUT touching wasStopped
    private func stopCurrentAudio() {
        currentTask?.cancel()
        currentTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func playAudio(data: Data) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            print("▶️ SpeechManager: playing OpenAI TTS audio")
        } catch {
            print("❌ SpeechManager: failed to play audio - \(error)")
            DispatchQueue.main.async { self.isSpeaking = false }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension SpeechManager: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("✅ SpeechManager: audio finished (success: \(flag), wasStopped: \(wasStopped))")
        DispatchQueue.main.async { self.isSpeaking = false }

        guard flag && !wasStopped else { return }

        print("✅ SpeechManager: triggering onFinishedSpeaking callback")
        // Minimal delay just to let audio session settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.onFinishedSpeaking?()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ SpeechManager: decode error - \(String(describing: error))")
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
