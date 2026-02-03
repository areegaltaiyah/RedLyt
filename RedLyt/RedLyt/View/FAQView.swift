import SwiftUI

struct FAQView : View {
    var body: some View {
        NavigationStack {
            // --- Your content started here ---
            ZStack {
                Color(uiColor: .systemGray6).ignoresSafeArea() // Gives the card-background contrast
                
                ScrollView {
                    VStack(spacing: 16) {
                        // These cards match the design in your screenshot
                        FAQCard(question: "How do I talk to the AI without taking my hands off the wheel?",
                                answer: "The app is designed to be 100% voice-activated. The AI will pause automatically whenever it detects you speaking, allowing for a natural, hands-free conversation.")
                        
                        FAQCard(question: "Do I need to sign up?",
                                answer: "No You can start listening without creating an account. Signing up later helps personalize the experience, but it’s optional.")
                        
                        FAQCard(question: "Is it CarPlay compatible?",
                                answer: "Absolutely. RedLyt is designed to work seamlessly with CarPlay so you can stay focused on the road.")
                        
                        FAQCard(question: " How does the app help me stay awake?                    ",
                                answer: "The AI uses Active Engagement. Depending on your trip length, it will check in periodically with questions, trivia, or interactive storytelling to keep your brain stimulated and monitor your alertness.")
                    }
                    .padding()
                }
            }
            // --- Your content ended here ---
            
            //-----Navigation Bar-----
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            
            //ToolBar Chevron Left
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Action
                    }) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
    }
}

//  the card styling
struct FAQCard: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                Text(question)
                    .font(.headline)
            }
            Text(answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    FAQView()
}
