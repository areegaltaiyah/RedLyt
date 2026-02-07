import SwiftUI

struct PodcastHostView: View {
    @State private var isRecording = false
    @State private var userAudioLevel: CGFloat = 0.5
    @State private var aiAudioLevel: CGFloat = 0.7
    
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("7")
                            .font(.system(size: 43, weight: .bold, design: .default).width(.expanded))
                        Text("Minutes")
                            .font(.system(size: 43, weight: .bold, design: .default).width(.expanded))
                        Text("left!")
                            .font(.system(size: 43, weight: .bold, design: .default).width(.expanded))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Audio Visualization
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
                    .frame(height: 400)
                    
                    Spacer()
                    
                    // Mic
                    Button {
                        isRecording.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red.opacity(0.5) : Color("MicColor").opacity(0.5))
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
            .preferredColorScheme(.dark)
        }
    }
    
    // Helper moved outside body
    func getHeight(_ index: Int) -> CGFloat {
        let mid: CGFloat = 4
        let distance = abs(CGFloat(index) - mid)
        return 60 - (distance * 12)
    }
    
    struct AIOrb: View {
        let level: CGFloat
        @State private var pulse = false
        @State private var shimmer = false
        
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
                
                // Ai Bubble
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color("Bubble").opacity(0.6),
                                    Color("Bubble").opacity(0.4),
                                    Color("Bubble").opacity(0.2)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 77
                            )
                        )
                        .frame(width: 154 + level * 20, height: 154 + level * 20)
                    
                    // Border
                    Circle()
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
                        .frame(width: 154 + level * 20, height: 154 + level * 20)
                        .blur(radius: 1)
                }
                .blur(radius: 8)
                
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
                    .opacity(shimmer ? 0.8 : 0.5)
                
                // Scd Highlight
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
                    .opacity(shimmer ? 0.6 : 0.3)
            }
            .scaleEffect(pulse ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: shimmer)
            .onAppear {
                pulse = true
                shimmer = true
            }
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
}

// Preview moved to file scope
#Preview {
    PodcastHostView()
}
