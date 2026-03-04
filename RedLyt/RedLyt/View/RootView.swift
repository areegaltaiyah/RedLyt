//
//  Untitled.swift
//  RedLyt
//
//  Created by Shahd Muharrq on 15/09/1447 AH.
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashSc()
                    .transition(.opacity)
            } else {
                PodcastHostView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut) {
                    showSplash = false
                }
            }
        }
    }
}
