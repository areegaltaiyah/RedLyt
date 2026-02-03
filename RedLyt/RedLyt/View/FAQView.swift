//
//  FAQView.swift
//  RedLyt
//
//  Created by Areeg Altaiyah on 03/02/2026.
//

import SwiftUI
struct FAQView : View {
    var body: some View {
        NavigationStack {
            // Your content
            Text("Main Content")
            
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

#Preview {
    FAQView()
}
