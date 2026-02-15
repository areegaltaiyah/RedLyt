import SwiftUI

struct FAQView : View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            // --- Your content started here ---
            ZStack {
                Color(uiColor: .redlyteBg).ignoresSafeArea() // Gives the card-background contrast
                
                ScrollView {
                    VStack(spacing: 16) {
                        // These cards match the design in your screenshot
                        FAQCard(question: "How do I talk to the AI without taking my hands off the wheel?",
                                answer: "The app is designed to be 100% voice-activated. The AI will pause automatically whenever it detects you speaking, allowing for a natural, hands-free conversation.")
                        
                        FAQCard(question: "Do I need to sign up?",
                                answer: "No, You can start listening without creating an account. We might add Signing up later helps personalize the experience, but it's optional.")
                        
                        FAQCard(question: "Is it CarPlay compatible?",
                                answer: "Absolutely. RedLyt is designed to work seamlessly with CarPlay so you can stay focused on the road.")
                        
                        FAQCard(question: "How does the app help me stay awake?",
                                answer: "The AI uses Active Engagement. Depending on your trip length, it will check in periodically with questions, trivia, or interactive storytelling to keep your brain stimulated and monitor your alertness.")
                        
                        
                    }
                    .padding()
                }
            }
            // --- Your content ended here ---
            
            //-----Navigation Bar-----
            
            .navigationBarTitleDisplayMode(.inline)
            //ToolBar Chevron Left
            .toolbar {
                ToolbarItem(placement: .principal){
                    Text("FAQ")
                        .font(.headline.weight(.bold).width(.expanded))
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
                    .font(.headline).foregroundColor(.primary)
            }
            Text(answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.redlyteBg)
        .cornerRadius(14)
        .shadow(color: Color.primary.opacity(0.2), radius: 70, x: 0, y: 4)
    }
}

#Preview {
    FAQView()
}
