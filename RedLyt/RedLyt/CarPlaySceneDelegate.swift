//
//  CarPlaySceneDelegate.swift
//  RedLyt
//

import CarPlay
import UIKit
import MediaPlayer

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    var speechRecognizer: SpeechRecognizer?
    var speechManager: SpeechManager?
    var conversationHistory: [Message] = []
    var isConversationActive = false
    var isLoading = false
    
    override init() {
        super.init()
        setupRemoteCommandCenter()
    }
    
    // MARK: - CarPlay Connection
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        print("🚗 CarPlay connected!")
        
        // Initialize speech components (use your existing classes)
        setupSpeechComponents()
        
        // Show Now Playing screen
        showNowPlayingScreen()
        
        // Start the podcast automatically
        startPodcastConversation()
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        print("🚗 CarPlay disconnected!")
        
        stopPodcastConversation()
        cleanupSpeechComponents()
        self.interfaceController = nil
    }
    
    // MARK: - Speech Setup (Uses YOUR existing classes)
    
    func setupSpeechComponents() {
        // Use YOUR existing SpeechRecognizer
        speechRecognizer = SpeechRecognizer()
        speechRecognizer?.onUserFinishedSpeaking = { [weak self] userText in
            guard let self = self, !userText.isEmpty else { return }
            
            print("📝 User said: '\(userText)'")
            self.conversationHistory.append(Message(role: "user", content: userText))
            
            Task {
                await self.getAIResponse(to: userText)
            }
        }
        
        // Use YOUR existing SpeechManager
        speechManager = SpeechManager()
        speechManager?.onFinishedSpeaking = { [weak self] in
            guard let self = self, self.isConversationActive else { return }
            
            print("✅ AI finished speaking - opening mic in 1 second")
            self.startListeningWithDelay(delay: 1.0)
        }
    }
    
    func cleanupSpeechComponents() {
        speechRecognizer?.stopListening()
        speechManager?.stop()
        speechRecognizer = nil
        speechManager = nil
        conversationHistory = []
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Podcast Conversation
    
    func startPodcastConversation() {
        guard conversationHistory.isEmpty else { return }
        
        print("🎙️ Starting AI podcast conversation...")
        
        isConversationActive = true
        
        // Update Now Playing with "Starting..."
        updateNowPlayingInfo(status: "Starting conversation...")
        
        // Check API key
        guard ApiKeys.openAI != nil else {
            print("❌ Missing OpenAI API Key!")
            updateNowPlayingInfo(status: "Error: Missing API Key")
            return
        }
        
        // Start with AI greeting
        Task {
            await sendInitialGreeting()
        }
    }
    
    func stopPodcastConversation() {
        print("⏹️ Stopping podcast conversation...")
        
        isConversationActive = false
        speechRecognizer?.stopListening()
        speechManager?.stop()
        
        updateNowPlayingInfo(status: "Conversation ended")
    }
    
    func sendInitialGreeting() async {
        isLoading = true
        updateNowPlayingInfo(status: "AI is thinking...")
        
        defer { isLoading = false }
        
        // Use YOUR existing OpenAIService
        let service = OpenAIService()
        let systemPrompt = Prompts.podcastHostBase
        let userPrompt = "Start the show with a short, friendly greeting to the driver. Keep it under 20 words."
        
        do {
            let result = try await service.generateReply(
                system: systemPrompt,
                conversationHistory: [],
                userMessage: userPrompt
            )
            
            print("✅ AI Greeting:", result)
            conversationHistory.append(Message(role: "assistant", content: result))
            
            await speakAIResponse(result)
            
        } catch {
            print("❌ Error getting AI greeting:", error)
            updateNowPlayingInfo(status: "Connection error")
            
            // Retry after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await sendInitialGreeting()
        }
    }
    
    func getAIResponse(to userMessage: String) async {
        guard isConversationActive else { return }
        
        isLoading = true
        updateNowPlayingInfo(status: "AI is thinking...")
        
        defer { isLoading = false }
        
        // Use YOUR existing OpenAIService
        let service = OpenAIService()
        let systemPrompt = Prompts.podcastHostBase
        
        do {
            let result = try await service.generateReply(
                system: systemPrompt,
                conversationHistory: conversationHistory,
                userMessage: userMessage
            )
            
            print("✅ AI Reply:", result)
            conversationHistory.append(Message(role: "assistant", content: result))
            
            // Small delay before speaking
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await speakAIResponse(result)
            
        } catch {
            print("❌ AI Error:", error)
            updateNowPlayingInfo(status: "Connection error")
            
            // Retry listening after error
            if isConversationActive {
                startListeningWithDelay(delay: 2.0)
            }
        }
    }
    
    func speakAIResponse(_ text: String) async {
        print("🔊 AI speaking: '\(text)'")
        
        updateNowPlayingInfo(status: "AI is speaking...")
        
        await MainActor.run {
            // Use YOUR existing SpeechManager
            speechManager?.speak(text)
        }
    }
    
    func startListeningWithDelay(delay: TimeInterval = 1.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            let canStart = self.isConversationActive &&
                           !self.isLoading &&
                           !(self.speechManager?.isSpeaking ?? false) &&
                           !(self.speechRecognizer?.isListening ?? false)
            
            guard canStart else {
                print("⏭️ Can't start listening - conditions not met")
                return
            }
            
            print("🎤 Opening mic...")
            self.updateNowPlayingInfo(status: "Listening...")
            self.speechRecognizer?.startListening()
        }
    }
    
    // MARK: - Now Playing UI
    
    func showNowPlayingScreen() {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        interfaceController?.setRootTemplate(nowPlayingTemplate, animated: true, completion: nil)
        
        print("📺 Now Playing screen displayed")
    }
    
    func updateNowPlayingInfo(status: String) {
        var nowPlayingInfo = [String: Any]()
        
        // Main info
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Podcast Host"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "AI Host • RedLyt"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = status
        
        // Show as "playing"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isConversationActive ? 1.0 : 0.0
        
        // Artwork - changes based on status
        let iconName: String
        let iconColor: UIColor
        
        if status.contains("Listening") {
            iconName = "mic.circle.fill"
            iconColor = .systemBlue
        } else if status.contains("speaking") {
            iconName = "waveform.circle.fill"
            iconColor = .systemGreen
        } else if status.contains("thinking") {
            iconName = "brain.head.profile"
            iconColor = .systemOrange
        } else if status.contains("error") || status.contains("Error") {
            iconName = "exclamationmark.triangle.fill"
            iconColor = .systemRed
        } else {
            iconName = "antenna.radiowaves.left.and.right.circle.fill"
            iconColor = .systemBlue
        }
        
        if let image = UIImage(systemName: iconName)?.withTintColor(iconColor, renderingMode: .alwaysOriginal) {
            let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 512, height: 512)) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        print("📊 Status: \(status)")
    }
    
    // MARK: - Remote Control
    
    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Stop button - ends conversation
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stopPodcastConversation()
            return .success
        }
        
        // Disable other buttons
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
    }
}
