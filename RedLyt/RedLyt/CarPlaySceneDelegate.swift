import CarPlay
import UIKit
import MediaPlayer

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    var isRecording = false
    var minutesLeft = 7
    var recordingTimer: Timer?
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        showPodcastInterface()
    }

    // 🎙️ واجهة البودكاست
    func showPodcastInterface() {
        let micItem = CPListItem(
            text: isRecording ? "⏹️ Stop Recording" : "🎙️ Start Interview",
            detailText: isRecording ? "\(minutesLeft) Minutes remaining" : "\(minutesLeft) Minutes • Tap to begin"
        )
        
        // أيقونة ملونة
        let micImage: UIImage?
        if isRecording {
            micImage = UIImage(systemName: "record.circle.fill")?
                .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        } else {
            micImage = UIImage(systemName: "mic.circle.fill")?
                .withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        }
        micItem.setImage(micImage)
        
        micItem.handler = { [weak self] item, completion in
            self?.toggleRecording()
            completion() // ✅ إضافة completion
        }

        let section = CPListSection(items: [micItem])
        let template = CPListTemplate(title: "Podcast Host", sections: [section])
        
        interfaceController?.setRootTemplate(template, animated: true, completion: nil)
    }
    
    func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    func startRecording() {
        print("🎙️ بدء المقابلة...")
        
        setupNowPlayingInfo()
        showNowPlayingScreen()
        startCountdown()
    }
    
    func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Podcast Interview"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "AI Host • RedLyt"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "\(minutesLeft) Minutes Remaining"
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = TimeInterval(minutesLeft * 60)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        if let image = UIImage(systemName: "waveform.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 512, height: 512)) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func showNowPlayingScreen() {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        interfaceController?.pushTemplate(nowPlayingTemplate, animated: true, completion: nil)
    }
    
    func stopRecording() {
        print("⏹️ إيقاف المقابلة...")
        
        stopCountdown()
        minutesLeft = 7
        isRecording = false
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // ✅ التحقق من وجود templates قبل الـ pop
        if let templates = interfaceController?.templates, templates.count > 1 {
            // نحن في شاشة Now Playing، نرجع للرئيسية
            interfaceController?.popToRootTemplate(animated: true) { [weak self] _, _ in
                self?.showPodcastInterface()
            }
        } else {
            // نحن بالفعل في الشاشة الرئيسية، نحدثها فقط
            showPodcastInterface()
        }
    }
    
    func startCountdown() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording else {
                timer.invalidate()
                return
            }
            
            self.minutesLeft -= 1
            
            if self.minutesLeft <= 0 {
                self.stopRecording()
                return
            }
            
            self.setupNowPlayingInfo()
        }
    }
    
    func stopCountdown() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        stopCountdown()
        self.interfaceController = nil
    }
}
