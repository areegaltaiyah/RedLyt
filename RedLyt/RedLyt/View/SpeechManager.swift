import Foundation
import AVFoundation
import Combine

final class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    private let synth = AVSpeechSynthesizer()

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
}
