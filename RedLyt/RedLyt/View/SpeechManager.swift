import Foundation
import AVFoundation
import Combine

final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    private let synth = AVSpeechSynthesizer()

    // Notify listeners when TTS finishes speaking
    var onSpeechFinished: (() -> Void)?

    override init() {
        super.init()
        synth.delegate = self

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }

    func speak(_ text: String, language: String = "en-US") {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }

        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: language)
        u.rate = 0.48
        u.volume = 1.0
        synth.speak(u)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.onSpeechFinished?()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // Treat cancel as finished if you still want to resume listening
        DispatchQueue.main.async { [weak self] in
            self?.onSpeechFinished?()
        }
    }
}
