//
//  FundSelectionView.swift
//  Rabbit Invest
//
//  Created by Kanav Nijhawan on 20/08/25.
//

import SwiftUI
import Combine

struct FundSelectionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var apiService = APIService.shared
    
    @State private var allFunds: [Fund] = []
    @State private var filteredFunds: [Fund] = []
    @State private var filters = FundFilters()
    @State private var isSearchFocused: Bool = false
    @State private var showFilters: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    // Filter options
    @State private var availableAMCs: [String] = []
    @State private var availableCategories: [String] = []
    @State private var availableTypes: [String] = []
    
    // Combine cancellables for API calls
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Search and Filter Section
                    searchAndFilterSection
                    
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        // Fund List
                        fundListView
                    }
                    
                    // Bottom Action Bar
                    bottomActionBar
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadFunds()
        }
        .sheet(isPresented: $showFilters) {
            FiltersView(
                filters: $filters,
                availableAMCs: availableAMCs,
                availableCategories: availableCategories,
                availableTypes: availableTypes,
                onApply: applyFilters
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: AppLayout.mediumPadding) {
            HStack {
                VStack(alignment: .leading, spacing: AppLayout.extraSmallPadding) {
                    Text("Welcome back!")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(appState.user?.email ?? "User")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: AppLayout.mediumPadding) {
                    // Favorites Button - Icon only
                    Button(action: {
                        appState.currentScreen = .favorites
                    }) {
                        ZStack {
                            Circle()
                                .fill(AppColors.cardBackground)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: appState.favoriteFunds.isEmpty ? "star" : "star.fill")
                                .font(.title)
                                .foregroundColor(AppColors.primaryGreen)
                        }
                        .overlay(
                            // Favorites count badge
                            appState.favoriteFunds.count > 0 ? 
                            ZStack {
                                Circle()
                                    .fill(AppColors.primaryGreen)
                                    .frame(width: 20, height: 20)
                                
                                Text("\(appState.favoriteFunds.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(AppColors.primaryBackground)
                            }
                            .offset(x: 14, y: -14) : nil
                        )
                    }
                    
                    // Profile/Menu Button
                    Menu {
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
            
            // Title
            HStack {
                Text("Select Mutual Funds")
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Text("\(appState.selectedFunds.count)/4")
                    .font(AppFonts.callout)
                    .foregroundColor(appState.selectedFunds.count >= 2 ? AppColors.primaryGreen : AppColors.secondaryText)
                    .padding(.horizontal, AppLayout.mediumPadding)
                    .padding(.vertical, AppLayout.smallPadding)
                    .background(
                        RoundedRectangle(cornerRadius: AppLayout.smallCornerRadius)
                            .fill(AppColors.cardBackground)
                    )
            }
            .padding(.horizontal, AppLayout.largePadding)
        }
        .padding(.bottom, AppLayout.smallPadding)
        .background(AppColors.secondaryBackground)
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: AppLayout.mediumPadding) {
            // Compact Search and Filter Row
            HStack(spacing: AppLayout.smallPadding) {
                // Compact Search Bar
                HStack(spacing: AppLayout.smallPadding) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.tertiaryText)
                        .font(.callout)
                    
                    TextField("Search funds...", text: $filters.searchText)
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.primaryText)
                        .onTapGesture {
                            isSearchFocused = true
                        }
                }
                .padding(.horizontal, AppLayout.mediumPadding)
                .padding(.vertical, 12)
                .background(AppColors.cardBackground)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isSearchFocused ? AppColors.primaryGreen : Color.clear, 
                               lineWidth: 2)
                )
                
                // Compact Filter Button
                Button(action: {
                    showFilters = true
                }) {
                    ZStack {
                        Circle()
                            .fill(hasActiveFilters ? AppColors.primaryGreen : AppColors.cardBackground)
                        
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(hasActiveFilters ? AppColors.primaryBackground : AppColors.primaryGreen)
                    }
                    .frame(width: 50, height: 50)
                }
                .overlay(
                    // Active filter count badge
                    hasActiveFilters ? 
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGreen)
                            .frame(width: 16, height: 16)
                        
                        Text("\(activeFilterCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppColors.primaryBackground)
                    }
                    .offset(x: 15, y: -12) : nil
                )
            }
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.top, AppLayout.mediumPadding)
            
            // Compact Active Filters Display
            if hasActiveFilters {
                compactActiveFiltersView
                    .padding(.top, AppLayout.smallPadding)
            }
        }
        .padding(.bottom, AppLayout.mediumPadding)
        .onChange(of: filters.searchText) { _ in
            applyFilters()
        }
    }
    
    // MARK: - Active Filters View
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.smallPadding) {
                if !filters.selectedAMC.isEmpty {
                    filterChip(title: "AMC: \(filters.selectedAMC)") {
                        filters.selectedAMC = ""
                        applyFilters()
                    }
                }
                
                if !filters.selectedCategory.isEmpty {
                    filterChip(title: "Category: \(filters.selectedCategory)") {
                        filters.selectedCategory = ""
                        applyFilters()
                    }
                }
                
                if !filters.selectedType.isEmpty {
                    filterChip(title: "Type: \(filters.selectedType)") {
                        filters.selectedType = ""
                        applyFilters()
                    }
                }
                
                Button("Clear All") {
                    clearAllFilters()
                }
                .font(AppFonts.caption)
                .foregroundColor(AppColors.errorRed)
            }
            .padding(.horizontal, AppLayout.largePadding)
        }
    }
    
    // MARK: - Compact Active Filters View
    private var compactActiveFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.smallPadding) {
                if !filters.selectedAMC.isEmpty {
                    compactFilterChip(title: filters.selectedAMC, type: "AMC") {
                        filters.selectedAMC = ""
                        applyFilters()
                    }
                }
                
                if !filters.selectedCategory.isEmpty {
                    compactFilterChip(title: filters.selectedCategory, type: "Category") {
                        filters.selectedCategory = ""
                        applyFilters()
                    }
                }
                
                if !filters.selectedType.isEmpty {
                    compactFilterChip(title: filters.selectedType, type: "Type") {
                        filters.selectedType = ""
                        applyFilters()
                    }
                }
                
                Button("Clear All") {
                    clearAllFilters()
                }
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.errorRed)
                .padding(.horizontal, AppLayout.smallPadding)
                .padding(.vertical, AppLayout.extraSmallPadding)
                .background(
                    RoundedRectangle(cornerRadius: AppLayout.extraSmallPadding)
                        .fill(AppColors.errorRed.opacity(0.1))
                )
            }
            .padding(.horizontal, AppLayout.largePadding)
        }
    }
    
    // MARK: - Compact Filter Chip
    private func compactFilterChip(title: String, type: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: AppLayout.extraSmallPadding) {
            Text(title)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.primaryText)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.horizontal, AppLayout.smallPadding)
        .padding(.vertical, AppLayout.extraSmallPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.extraSmallPadding)
                .fill(AppColors.primaryGreen.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.extraSmallPadding)
                        .stroke(AppColors.primaryGreen.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Filter Chip
    private func filterChip(title: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: AppLayout.smallPadding) {
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.primaryText)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.secondaryText)
                    .font(.caption)
            }
        }
        .padding(.horizontal, AppLayout.mediumPadding)
        .padding(.vertical, AppLayout.smallPadding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.smallCornerRadius)
                .fill(AppColors.cardBackground)
        )
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: AppLayout.largePadding) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                .scaleEffect(1.5)
            
            Text("Loading mutual funds...")
                .font(AppFonts.callout)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: AppLayout.largePadding) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColors.errorRed)
            
            Text("Something went wrong")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primaryText)
            
            Text(error)
                .font(AppFonts.callout)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppLayout.largePadding)
            
            Button("Try Again") {
                loadFunds()
            }
            .primaryButtonStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Fund List View
    private var fundListView: some View {
        ScrollView {
            LazyVStack(spacing: AppLayout.mediumPadding) {
                ForEach(filteredFunds) { fund in
                    FundRowView(
                        fund: fund,
                        isSelected: appState.selectedFunds.contains(fund),
                        canSelect: appState.selectedFunds.count < 4 || appState.selectedFunds.contains(fund),
                        onToggle: {
                            appState.toggleFundSelection(fund)
                        }
                    )
                }
                
                if filteredFunds.isEmpty {
                    emptyStateView
                }
            }
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.top, AppLayout.smallPadding)
            .padding(.bottom, 100) // Space for bottom bar
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AppLayout.largePadding) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(AppColors.tertiaryText)
            
            Text("No funds found")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primaryText)
            
            Text("Try adjusting your search or filters")
                .font(AppFonts.callout)
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(.vertical, AppLayout.extraLargePadding)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            // Subtle top border
            Rectangle()
                .fill(AppColors.borderColor.opacity(0.3))
                .frame(height: 0.5)
            
            HStack(spacing: AppLayout.mediumPadding) {
                // Selection Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(appState.selectedFunds.count) of 4 selected")
                        .font(AppFonts.callout.weight(.medium))
                        .foregroundColor(AppColors.primaryText)
                    
                    if appState.selectedFunds.count < 2 {
                        Text("Select at least 2 funds")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.secondaryText)
                    } else {
                        Text("Ready to compare")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.primaryGreen)
                    }
                }
                
                Spacer()
                
                // Modern iOS-style Action Button
                Button(action: {
                    appState.currentScreen = .comparison
                }) {
                    HStack(spacing: AppLayout.smallPadding) {
                        Text("Compare")
                            .font(AppFonts.headline)
                        
                        if appState.canShowComparison {
                            Image(systemName: "arrow.right")
                                .font(.callout.weight(.medium))
                        }
                    }
                    .foregroundColor(appState.canShowComparison ? AppColors.primaryBackground : AppColors.tertiaryText)
                    .padding(.horizontal, AppLayout.largePadding)
                    .padding(.vertical, AppLayout.mediumPadding)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(appState.canShowComparison ? AppColors.primaryGreen : AppColors.borderColor)
                    )
                    .scaleEffect(appState.canShowComparison ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.2), value: appState.canShowComparison)
                }
                .disabled(!appState.canShowComparison)
            }
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.vertical, AppLayout.mediumPadding)
            .background(
                AppColors.secondaryBackground
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: -1)
            )
        }
    }
    
    // MARK: - Computed Properties
    private var hasActiveFilters: Bool {
        !filters.selectedAMC.isEmpty || !filters.selectedCategory.isEmpty || !filters.selectedType.isEmpty
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if !filters.selectedAMC.isEmpty { count += 1 }
        if !filters.selectedCategory.isEmpty { count += 1 }
        if !filters.selectedType.isEmpty { count += 1 }
        return count
    }
    
    // MARK: - Functions
    private func loadFunds() {
        isLoading = true
        errorMessage = nil
        
        print("🚀 Starting API call to fetch funds...")
        
        // Fetch real funds from API
        apiService.fetchAllFunds()
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        switch completion {
                        case .finished:
                            print("✅ API call completed successfully")
                        case .failure(let error):
                            print("❌ API call failed: \(error.localizedDescription)")
                            self.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { funds in
                    DispatchQueue.main.async {
                        print("📊 Received \(funds.count) funds from API")
                        self.allFunds = funds
                        self.setupFilterOptions()
                        
                        // Restore previously selected funds
                        self.appState.restoreSelectedFunds(from: self.allFunds)
                        
                        // Restore favorite funds
                        self.appState.restoreFavoriteFunds(from: self.allFunds)
                        
                        // Load persisted filters
                        self.filters = DataPersistenceService.shared.getLastFilters()
                        
                        self.applyFilters()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupFilterOptions() {
        availableAMCs = apiService.getUniqueAMCs(from: allFunds)
        availableCategories = apiService.getUniqueCategories(from: allFunds)
        availableTypes = apiService.getUniqueTypes(from: allFunds)
    }
    
    private func applyFilters() {
        let filtered = apiService.filterFunds(funds: allFunds, with: filters)
        
        // Move selected funds to the top
        let selectedFunds = filtered.filter { appState.selectedFunds.contains($0) }
        let unselectedFunds = filtered.filter { !appState.selectedFunds.contains($0) }
        filteredFunds = selectedFunds + unselectedFunds
        
        // Save filters to persistence
        DataPersistenceService.shared.saveFilters(filters)
        
        // Save search term to history if it's not empty
        if !filters.searchText.isEmpty {
            DataPersistenceService.shared.addToSearchHistory(filters.searchText)
        }
    }
    
    private func clearAllFilters() {
        filters = FundFilters()
        applyFilters()
    }
}

// MARK: - Fund Row View
struct FundRowView: View {
    @EnvironmentObject var appState: AppState
    let fund: Fund
    let isSelected: Bool
    let canSelect: Bool
    let onToggle: () -> Void
    
    @State private var showFavoriteAlert = false
    
    var body: some View {
        HStack(spacing: AppLayout.mediumPadding) {
            // Selection Indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? AppColors.primaryGreen : AppColors.borderColor, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Circle()
                        .fill(AppColors.primaryGreen)
                        .frame(width: 16, height: 16)
                    
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppColors.primaryBackground)
                }
            }
            
            // Fund Info
            VStack(alignment: .leading, spacing: AppLayout.smallPadding) {
                Text(fund.schemeName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(2)
                
                if let fundHouse = fund.fundHouse {
                    Text(fundHouse)
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(1)
                }
                
                HStack {
                    if let category = fund.schemeCategory {
                        fundInfoChip(text: category)
                    }
                    
                    if let amc = fund.amc {
                        fundInfoChip(text: amc)
                    }
                }
            }
            
            Spacer()
            
            // Favorite Toggle
            Button(action: {
                if appState.isFavorite(fund) {
                    // Remove from favorites
                    appState.removeFromFavorites(fund)
                } else {
                    // Try to add to favorites
                    let success = appState.addToFavorites(fund)
                    if !success {
                        showFavoriteAlert = true
                    }
                }
            }) {
                Image(systemName: appState.isFavorite(fund) ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(appState.isFavorite(fund) ? AppColors.primaryGreen : AppColors.secondaryText)
            }
            .alert("Favorites Limit Reached", isPresented: $showFavoriteAlert) {
                Button("OK") { }
            } message: {
                Text("You can only have up to 5 favorite funds. Remove some favorites to add new ones.")
            }
        }
        .padding(AppLayout.mediumPadding)
        .cardStyle()
        .opacity(canSelect ? 1.0 : 0.6)
        .onTapGesture {
            if canSelect {
                onToggle()
            }
        }
    }
    
    private func fundInfoChip(text: String) -> some View {
        Text(text)
            .font(AppFonts.caption)
            .foregroundColor(AppColors.tertiaryText)
            .padding(.horizontal, AppLayout.smallPadding)
            .padding(.vertical, AppLayout.extraSmallPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.smallCornerRadius)
                    .fill(AppColors.secondaryBackground)
            )
            .lineLimit(1)
    }
}

#Preview {
    FundSelectionView()
        .environmentObject(AppState())
}
