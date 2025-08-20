//
//  FavoritesView.swift
//  Rabbit Invest
//
//  Created by Kanav Nijhawan on 20/08/25.
//

import SwiftUI
import Combine

struct FavoritesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var apiService = APIService.shared
    
    @State private var latestNAVMap: [String: String] = [:]
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // Combine cancellables for API calls
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    if appState.favoriteFunds.isEmpty {
                        emptyStateView
                    } else {
                        favoritesList
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadLatestNAVForFavorites()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: AppLayout.mediumPadding) {
            HStack {
                Button(action: {
                    appState.currentScreen = .fundSelection
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "chevron.left")
                            .font(.title.weight(.semibold))
                            .foregroundColor(AppColors.primaryGreen)
                    }
                }
                
                Spacer()
                
                HStack(spacing: AppLayout.mediumPadding) {
                    // Refresh Button
                    Button(action: {
                        loadLatestNAVForFavorites()
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "arrow.clockwise")
                                .font(.title)
                                .foregroundColor(isLoading ? AppColors.tertiaryText : AppColors.primaryGreen)
                                .rotationEffect(.degrees(isLoading ? 360 : 0))
                                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                        }
                    }
                    .disabled(isLoading)
                    
                    // Profile/Menu Button
                    Menu {
                        Button(action: {
                            appState.currentScreen = .fundSelection
                        }) {
                            Label("Browse Funds", systemImage: "magnifyingglass")
                        }
                        
                        Button(action: {
                            appState.currentScreen = .comparison
                        }) {
                            Label("View Comparison", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .disabled(!appState.canShowComparison)
                        
                        Divider()
                        
                        Button(action: {
                            appState.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "person.circle")
                                .font(.title)
                                .foregroundColor(AppColors.primaryGreen)
                        }
                    }
                }
            }
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.top, AppLayout.mediumPadding)
            
            // Title and Count
            HStack {
                VStack(alignment: .leading, spacing: AppLayout.extraSmallPadding) {
                    Text("My Favorites")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("\(appState.favoriteFunds.count)/5 funds saved")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
            }
            .padding(.horizontal, AppLayout.largePadding)
        }
        .padding(.bottom, AppLayout.mediumPadding)
        .background(AppColors.secondaryBackground)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AppLayout.largePadding) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "star")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.primaryGreen)
            }
            
            VStack(spacing: AppLayout.mediumPadding) {
                Text("No Favorites Yet")
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.primaryText)
                
                Text("Add funds to your favorites list from the fund selection screen. You can save up to 5 funds and track their latest NAV.")
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppLayout.largePadding)
            }
            
            Button("Browse Funds") {
                appState.currentScreen = .fundSelection
            }
            .primaryButtonStyle()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Favorites List
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: AppLayout.mediumPadding) {
                ForEach(Array(appState.favoriteFunds.sorted(by: { $0.schemeName < $1.schemeName })), id: \.schemeCode) { fund in
                    FavoriteFundCard(
                        fund: fund,
                        latestNAV: latestNAVMap["\(fund.schemeCode)"],
                        isLoading: isLoading,
                        onRemove: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.removeFromFavorites(fund)
                            }
                        },
                        onSelect: {
                            // Add to comparison if possible
                            if appState.selectedFunds.count < 4 && !appState.selectedFunds.contains(fund) {
                                appState.selectFund(fund)
                            }
                            appState.currentScreen = .comparison
                        }
                    )
                }
            }
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.bottom, AppLayout.extraLargePadding)
        }
    }
    
    // MARK: - Functions
    private func loadLatestNAVForFavorites() {
        guard !appState.favoriteFunds.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Fetch real NAV data for favorite funds
        let schemeCodes = Array(appState.favoriteFunds).map { "\($0.schemeCode)" }
        
        apiService.fetchNAVDataForFunds(schemeCodes)
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if case .failure(let error) = completion {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { navResponseMap in
                    DispatchQueue.main.async {
                        var tempNAVMap: [String: String] = [:]
                        for (schemeCode, response) in navResponseMap {
                            tempNAVMap[schemeCode] = response.data.first?.nav ?? "N/A"
                        }
                        self.latestNAVMap = tempNAVMap
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Favorite Fund Card
struct FavoriteFundCard: View {
    let fund: Fund
    let latestNAV: String?
    let isLoading: Bool
    let onRemove: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: AppLayout.mediumPadding) {
            // Header with Star and Remove Button
            HStack {
                HStack(spacing: AppLayout.smallPadding) {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppColors.primaryGreen)
                    
                    Text(fund.schemeName)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            // Fund Details
            VStack(spacing: AppLayout.smallPadding) {
                HStack {
                    VStack(alignment: .leading, spacing: AppLayout.extraSmallPadding) {
                        Text("Fund House")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.tertiaryText)
                        Text(fund.fundHouse ?? "N/A")
                            .font(AppFonts.callout)
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppLayout.extraSmallPadding) {
                        Text("Latest NAV")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.tertiaryText)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                                .scaleEffect(0.8)
                        } else {
                            Text("₹\(latestNAV ?? "N/A")")
                                .font(AppFonts.callout.weight(.semibold))
                                .foregroundColor(AppColors.primaryGreen)
                        }
                    }
                }
                
                Divider()
                    .background(AppColors.dividerColor)
                
                HStack {
                    VStack(alignment: .leading, spacing: AppLayout.extraSmallPadding) {
                        Text("Category")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.tertiaryText)
                        Text(fund.schemeCategory ?? "N/A")
                            .font(AppFonts.callout)
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppLayout.extraSmallPadding) {
                        Text("Scheme Code")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.tertiaryText)
                        Text("\(fund.schemeCode)")
                            .font(AppFonts.callout.weight(.medium))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            
            // Action Button
            Button("Add to Comparison") {
                onSelect()
            }
            .secondaryButtonStyle()
        }
        .padding(AppLayout.mediumPadding)
        .cardStyle()
    }
}

#Preview {
    FavoritesView()
        .environmentObject({
            let appState = AppState()
            appState.favoriteFunds = Set([
                Fund(schemeCode: 120503, schemeName: "Sample Favorite Fund 1", isinGrowth: "INF123456789", isinDivReinvestment: nil),
                Fund(schemeCode: 120504, schemeName: "Sample Favorite Fund 2", isinGrowth: "INF987654321", isinDivReinvestment: nil)
            ])
            return appState
        }())
}
