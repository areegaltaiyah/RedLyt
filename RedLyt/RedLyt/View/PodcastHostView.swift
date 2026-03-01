import SwiftUI

struct PodcastHostView: View {
    @State private var isRecording = false
    @State private var userAudioLevel: CGFloat = 0.5
    @State private var aiAudioLevel: CGFloat = 0.7
    @State private var isLoading = false
    @State private var conversationHistory: [Message] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isConversationActive = true
    
    @Environment(\.sizeCategory) private var sizeCategory
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Upper color").opacity(0.31),
                        Color.redlyteBg
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {}
                        .scaleEffect(sizeCategory.isAccessibilityCategory ? 1.0 : 1.06)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    ZStack {
                        HStack(spacing: 4) {
                            Spacer()
                            ForEach(0..<8) { i in
                                AudioBar(height: getHeight(i), level: speechRecognizer.audioLevel, isActive: isRecording)
                            }
                        }
                        .frame(width: 120)
                        .offset(x: -140)
                        
                        AIOrb(level: aiAudioLevel, isThinking: isLoading)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<8) { i in
                                AudioBar(height: getHeight(i), level: speechRecognizer.audioLevel, isActive: isRecording)
                            }
                            Spacer()
                        }
                        .frame(width: 120)
                        .offset(x: 140)
                    }
                    .frame(height: 400)
                    
                    Spacer()
                    
                    if isLoading {
                        Text("AI is thinking...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if speechRecognizer.isListening {
                        VStack(spacing: 4) {
                            Text("Listening...")
                                .font(.caption)
                                .foregroundColor(.blue)
                            if !speechRecognizer.transcript.isEmpty {
                                Text(speechRecognizer.transcript)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            Spacer()
                        }
                    } else if speechManager.isSpeaking {
                        Text("AI is speaking...")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(getIndicatorColor())
                            .frame(width: 70, height: 70)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: getIndicatorIcon())
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.blue, lineWidth: 3)
                            .frame(width: 80, height: 80)
                            .scaleEffect(isRecording ? 1.3 : 1.0)
                            .opacity(isRecording ? 0 : 1)
                            .animation(
                                isRecording ?
                                    .easeOut(duration: 1.0).repeatForever(autoreverses: false) :
                                    .default,
                                value: isRecording
                            )
                    )
                    
                    Button {
                        toggleConversation()
                    } label: {
                        HStack {
                            Image(systemName: isConversationActive ? "pause.circle.fill" : "play.circle.fill")
                            Text(isConversationActive ? "Pause Conversation" : "Resume Conversation")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Podcast Host")
                        .font(.headline.weight(.bold).width(.expanded))
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        FAQView()
                    } label: {
                        Text("?")
                            .font(.headline.weight(.bold).width(.expanded))
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                DebugHelper.checkAPIKeyStatus()
                setupSpeechRecognizer()
                setupSpeechManagerCallbacks()
                Task { await startConversation() }
            }
        }
    }
    
    func getHeight(_ index: Int) -> CGFloat {
        let mid: CGFloat = 4
        let distance = abs(CGFloat(index) - mid)
        return 60 - (distance * 12)
    }
    
    func getIndicatorColor() -> Color {
        if isLoading {
            return Color.orange.opacity(0.5)
        } else if isRecording {
            return Color.blue.opacity(0.5)
        } else if speechManager.isSpeaking {
            return Color.green.opacity(0.5)
        } else {
            return Color("MicColor").opacity(0.5)
        }
    }
    
    func getIndicatorIcon() -> String {
        if isRecording {
            return "waveform"
        } else if speechManager.isSpeaking {
            return "speaker.wave.3.fill"
        } else {
            return "mic.fill"
        }
    }
    
    func setupSpeechRecognizer() {
        speechRecognizer.onUserFinishedSpeaking = { [self] userText in
            guard !userText.isEmpty else {
                if isConversationActive {
                    startListeningWithDelay(delay: 0.3)
                }
                return
            }
            
            print("📝 User said: '\(userText)'")
            conversationHistory.append(Message(role: "user", content: userText))
            
            Task {
                await getAIResponse(to: userText)
            }
        }
    }
    
    func setupSpeechManagerCallbacks() {
        speechManager.onFinishedSpeaking = { [self] in
            print("✅ AI finished speaking - starting listening")
            if isConversationActive {
                startListeningWithDelay(delay: 0.3)
            }
        }
    }
    
    func toggleConversation() {
        isConversationActive.toggle()
        
        if isConversationActive {
            print("▶️ Conversation resumed")
            startListeningWithDelay(delay: 0.3)
        } else {
            print("⏸️ Conversation paused")
            speechRecognizer.stopListening()
            speechManager.stop()
            isRecording = false
        }
    }
    
    func startListeningWithDelay(delay: TimeInterval = 0.3) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isConversationActive && !isLoading && !speechManager.isSpeaking else {
                print("⏭️ Skipping auto-listen: active=\(isConversationActive) loading=\(isLoading) speaking=\(speechManager.isSpeaking)")
                return
            }
            
            isRecording = true
            speechRecognizer.startListening()
            print("🎤 Auto-started listening...")
        }
    }
    
    func startConversation() async {
        guard conversationHistory.isEmpty else { return }
        
        guard ApiKeys.openAI != nil else {
            errorMessage = """
            Missing OpenAI API Key!
            
            Please create Config.plist with your API key.
            Check the console for detailed instructions.
            """
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let service = OpenAIService()
        let systemPrompt = Prompts.podcastHostBase
        let userPrompt = "Start the show with a short, friendly greeting to the driver. Keep it under 20 words."
        
        do {
            let result = try await service.generateReply(
                system: systemPrompt,
                conversationHistory: [],
                userMessage: userPrompt
            )
            
            print("✅ AI Reply:", result)
            conversationHistory.append(Message(role: "assistant", content: result))
            await speakAIResponse(result)
            
        } catch OpenAIError.missingAPIKey {
            errorMessage = """
            Missing OpenAI API Key!
            
            Create a Config.plist file with:
            Key: OPEN_AI_API_KEY
            Value: Your OpenAI API key
            """
            showError = true
            
        } catch OpenAIError.badResponse {
            errorMessage = """
            Invalid API response.
            
            Possible causes:
            • Invalid API key
            • API key doesn't have credits
            • OpenAI service issue
            
            Check console for details.
            """
            showError = true
            
        } catch {
            print("❌ OpenAI error details:", error)
            errorMessage = """
            Connection failed: \(error.localizedDescription)
            
            Check:
            • Internet connection
            • API key is valid
            • Console logs for details
            """
            showError = true
        }
    }
    
    func getAIResponse(to userMessage: String) async {
        isLoading = true
        isRecording = false
        defer { isLoading = false }
        
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
            await speakAIResponse(result)
            
        } catch {
            print("❌ OpenAI error:", error)
            errorMessage = "AI host couldn't respond. Please try again."
            showError = true
            
            if isConversationActive {
                startListeningWithDelay(delay: 0.3)
            }
        }
    }
    
    func speakAIResponse(_ text: String) async {
        print("🔊 About to speak: '\(text)'")
        await MainActor.run {
            speechManager.speak(text)
        }
    }
    
    // ← كود زميلتك بدون أي تغيير
    struct AIOrb: View {
        let level: CGFloat
        let isThinking: Bool
        @State private var pulse = false
        @State private var shimmer = false
        @State private var rotate = false
        @State private var ripple1 = false
        @State private var ripple2 = false
        @State private var ripple3 = false
        @State private var morph = false
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("Bubble").opacity(0.36),
                                .clear
                            ],
                            center: .center,
                            startRadius: 100,
                            endRadius: 200
                        )
                    )
                    .frame(width: 281, height: 408)
                    .blur(radius: 40)
                
                Circle()
                    .strokeBorder(Color("Bubble").opacity(ripple3 ? 0.0 : 0.3), lineWidth: 1.5)
                    .frame(width: ripple3 ? 280 : 160, height: ripple3 ? 280 : 160)
                    .blur(radius: 2)
                    .animation(
                        .easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(0.8),
                        value: ripple3
                    )
                
                Circle()
                    .strokeBorder(Color("Bubble").opacity(ripple2 ? 0.0 : 0.45), lineWidth: 1.5)
                    .frame(width: ripple2 ? 240 : 160, height: ripple2 ? 240 : 160)
                    .blur(radius: 1.5)
                    .animation(
                        .easeOut(duration: 2.0).repeatForever(autoreverses: false).delay(0.4),
                        value: ripple2
                    )
                
                Circle()
                    .strokeBorder(Color("Bubble").opacity(ripple1 ? 0.0 : 0.6), lineWidth: 2)
                    .frame(width: ripple1 ? 200 : 160, height: ripple1 ? 200 : 160)
                    .blur(radius: 1)
                    .animation(
                        .easeOut(duration: 1.6).repeatForever(autoreverses: false),
                        value: ripple1
                    )
                
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color("Bubble").opacity(0.0),
                                Color("Bubble").opacity(0.7),
                                Color.white.opacity(0.4),
                                Color("Bubble").opacity(0.5),
                                Color("Bubble").opacity(0.0)
                            ],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 162, height: 162)
                    .rotationEffect(.degrees(rotate ? 360 : 0))
                    .animation(
                        .linear(duration: 4.0).repeatForever(autoreverses: false),
                        value: rotate
                    )
                    .blur(radius: 2)
                
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("Bubble").opacity(0.75),
                                Color("Bubble").opacity(0.5),
                                Color("Bubble").opacity(0.2)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 77
                        )
                    )
                    .frame(
                        width: (154 + level * 20) * (morph ? 1.06 : 0.96),
                        height: (154 + level * 20) * (morph ? 0.96 : 1.06)
                    )
                    .animation(
                        .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: morph
                    )
                    .blur(radius: 8)
                    .opacity(isThinking ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: isThinking)
                
                Ellipse()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color("Bubble").opacity(0.8),
                                Color("Bubble").opacity(0.4),
                                Color("Bubble").opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: (154 + level * 20) * (morph ? 1.06 : 0.96),
                        height: (154 + level * 20) * (morph ? 0.96 : 1.06)
                    )
                    .animation(
                        .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                        value: morph
                    )
                    .blur(radius: 1)
                
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.0)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(rotate ? -360 : 0))
                    .animation(
                        .linear(duration: 6.0).repeatForever(autoreverses: false),
                        value: rotate
                    )
                    .blur(radius: 4)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.3),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .offset(x: -30, y: -30)
                    .blur(radius: 8)
                    .opacity(shimmer ? 0.9 : 0.4)
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: shimmer
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .offset(x: 40, y: -15)
                    .blur(radius: 6)
                    .opacity(shimmer ? 0.7 : 0.25)
                    .animation(
                        .easeInOut(duration: 2.3).repeatForever(autoreverses: true).delay(0.5),
                        value: shimmer
                    )
                
                if isThinking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .scaleEffect(pulse ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)
            .onAppear {
                pulse = true
                shimmer = true
                rotate = true
                morph = true
                ripple1 = true
                ripple2 = true
                ripple3 = true
            }
        }
    }
    
    // ← كودي: الخطوط تتحرك فقط مع صوت اليوزر
    struct AudioBar: View {
        let height: CGFloat
        let level: CGFloat
        let isActive: Bool
        @State private var currentHeight: CGFloat = 4

        var body: some View {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.3, green: 0.5, blue: 0.9))
                .frame(width: 3, height: currentHeight)
                .onChange(of: level) { newLevel in
                    guard isActive else { return }
                    withAnimation(.easeInOut(duration: 0.1)) {
                        currentHeight = newLevel > 0.02
                            ? max(4, height * newLevel * CGFloat.random(in: 0.5...1.0))
                            : 4
                    }
                }
                .onChange(of: isActive) { active in
                    if !active {
                        withAnimation(.easeOut(duration: 0.3)) {
                            currentHeight = 4
                        }
                    }
                }
        }
    }
}

#Preview {
    PodcastHostView()
}
