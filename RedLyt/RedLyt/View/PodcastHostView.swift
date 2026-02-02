import SwiftUI

struct PodcastHostView: View {
    @State private var isRecording = false
    @State private var userAudioLevel: CGFloat = 0.5
    @State private var aiAudioLevel: CGFloat = 0.7
    
    var body: some View {
        ZStack {
            Color("Paleblue").ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 24))
                    Spacer()
                    Text("Podcast Host")
                        .font(.system(size: 20, weight: .bold, design: .default).width(.expanded))
                    Spacer()
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 24))
                        .opacity(0)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("7")
                        .font(.system(size: 43, weight: .bold, design: .default).width(.expanded))
                    Text("Minutes")
                        .font(.system(size: 43, weight: .bold, design: .default).width(.expanded))
                    Text("left!")
                        .font(.system(size: 43, weight: .bold, design: .default).width(.expanded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Audio lines
                ZStack {
                    HStack(spacing: 4) {
                        Spacer()
                        ForEach(0..<8) { i in
                            AudioBar(height: getHeight(i), level: userAudioLevel)
                        }
                    }
                    .frame(width: 120)
                    .offset(x: -140)
                    
                    AIOrb(level: aiAudioLevel)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<8) { i in
                            AudioBar(height: getHeight(i), level: userAudioLevel)
                        }
                        Spacer()
                    }
                    .frame(width: 120)
                    .offset(x: 140)
                }
                .frame(height: 300)
                
                Spacer()
                
                // Mic
                Button {
                    isRecording.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red.opacity(0.8) : Color(red: 0.3, green: 0.5, blue: 0.8))
                            .frame(width: 70, height: 70)
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func getHeight(_ index: Int) -> CGFloat {
        let mid: CGFloat = 4
        let distance = abs(CGFloat(index) - mid)
        return 60 - (distance * 12)
    }
}

struct AIOrb: View {
    let level: CGFloat
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.6), .clear],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 30)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.3, green: 0.5, blue: 1.0), Color(red: 0.15, green: 0.3, blue: 0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 160 + level * 40, height: 160 + level * 40)
                .blur(radius: 20)
        }
        .scaleEffect(pulse ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

struct AudioBar: View {
    let height: CGFloat
    let level: CGFloat
    @State private var currentHeight: CGFloat = 4
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(red: 0.3, green: 0.5, blue: 0.9))
            .frame(width: 3, height: currentHeight)
            .onAppear {
                animate()
            }
    }
    
    func animate() {
        withAnimation(.easeInOut(duration: 0.15)) {
            currentHeight = 4 + (height * level)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.1...0.3)) {
            animate()
        }
    }
}

#Preview {
    PodcastHostView()
}
