//
//  ContentView.swift
//  Rabbit Invest
//
//  Created by Kanav  Nijhawan on 20/08/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        ZStack {
            AppColors.primaryBackground.ignoresSafeArea()
            
            switch appState.currentScreen {
            case .login:
                LoginView()
                    .environmentObject(appState)
                    .transition(.move(edge: .leading))
                
            case .fundSelection:
                FundSelectionView()
                    .environmentObject(appState)
                    .transition(.move(edge: .trailing))
                
            case .comparison:
                ComparisonView()
                    .environmentObject(appState)
                    .transition(.move(edge: .trailing))
                
            case .favorites:
                FavoritesView()
                    .environmentObject(appState)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
        .preferredColorScheme(.dark) // Force dark mode for black theme
    }
}

#Preview {
    ContentView()
}
