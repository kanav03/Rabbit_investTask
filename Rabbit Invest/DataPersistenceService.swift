//
//  DataPersistenceService.swift
//  Rabbit Invest
//
//  Created by Kanav Nijhawan on 20/08/25.
//

import Foundation

class DataPersistenceService {
    static let shared = DataPersistenceService()
    
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private let userEmailKey = "user_email"
    private let selectedFundsKey = "selected_funds"
    private let lastFiltersKey = "last_filters"
    private let searchHistoryKey = "search_history"
    private let favoriteFundsKey = "favorite_funds"
    
    private init() {}
    
    // MARK: - User Data
    func saveUserEmail(_ email: String) {
        userDefaults.set(email, forKey: userEmailKey)
    }
    
    func getUserEmail() -> String? {
        return userDefaults.string(forKey: userEmailKey)
    }
    
    func clearUserData() {
        userDefaults.removeObject(forKey: userEmailKey)
        userDefaults.removeObject(forKey: selectedFundsKey)
        userDefaults.removeObject(forKey: lastFiltersKey)
        userDefaults.removeObject(forKey: searchHistoryKey)
        userDefaults.removeObject(forKey: favoriteFundsKey)
    }
    
    // MARK: - Selected Funds
    func saveSelectedFunds(_ funds: Set<Fund>) {
        let fundCodes = funds.map { "\($0.schemeCode)" }
        userDefaults.set(fundCodes, forKey: selectedFundsKey)
    }
    
    func getSelectedFundCodes() -> [String] {
        return userDefaults.array(forKey: selectedFundsKey) as? [String] ?? []
    }
    
    // MARK: - Filters
    func saveFilters(_ filters: FundFilters) {
        let filtersData = [
            "searchText": filters.searchText,
            "selectedAMC": filters.selectedAMC,
            "selectedCategory": filters.selectedCategory,
            "selectedType": filters.selectedType
        ]
        userDefaults.set(filtersData, forKey: lastFiltersKey)
    }
    
    func getLastFilters() -> FundFilters {
        guard let filtersData = userDefaults.dictionary(forKey: lastFiltersKey) else {
            return FundFilters()
        }
        
        var filters = FundFilters()
        filters.searchText = filtersData["searchText"] as? String ?? ""
        filters.selectedAMC = filtersData["selectedAMC"] as? String ?? ""
        filters.selectedCategory = filtersData["selectedCategory"] as? String ?? ""
        filters.selectedType = filtersData["selectedType"] as? String ?? ""
        
        return filters
    }
    
    // MARK: - Search History
    func addToSearchHistory(_ searchTerm: String) {
        guard !searchTerm.isEmpty else { return }
        
        var history = getSearchHistory()
        
        // Remove if already exists to avoid duplicates
        history.removeAll { $0 == searchTerm }
        
        // Add to beginning
        history.insert(searchTerm, at: 0)
        
        // Keep only last 10 searches
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
        
        userDefaults.set(history, forKey: searchHistoryKey)
    }
    
    func getSearchHistory() -> [String] {
        return userDefaults.array(forKey: searchHistoryKey) as? [String] ?? []
    }
    
    func clearSearchHistory() {
        userDefaults.removeObject(forKey: searchHistoryKey)
    }
    
    // MARK: - Favorite Funds
    func saveFavoriteFunds(_ funds: Set<Fund>) {
        let fundCodes = funds.map { "\($0.schemeCode)" }
        userDefaults.set(fundCodes, forKey: favoriteFundsKey)
    }
    
    func getFavoriteFundCodes() -> [String] {
        return userDefaults.array(forKey: favoriteFundsKey) as? [String] ?? []
    }
    
    func addToFavorites(_ fund: Fund) -> Bool {
        var favoriteCodes = getFavoriteFundCodes()
        
        // Check if already in favorites
        if favoriteCodes.contains("\(fund.schemeCode)") {
            return false
        }
        
        // Check max limit (5)
        if favoriteCodes.count >= 5 {
            return false
        }
        
        favoriteCodes.append("\(fund.schemeCode)")
        userDefaults.set(favoriteCodes, forKey: favoriteFundsKey)
        return true
    }
    
    func removeFromFavorites(_ fund: Fund) {
        var favoriteCodes = getFavoriteFundCodes()
        favoriteCodes.removeAll { $0 == "\(fund.schemeCode)" }
        userDefaults.set(favoriteCodes, forKey: favoriteFundsKey)
    }
    
    func isFavorite(_ fund: Fund) -> Bool {
        let favoriteCodes = getFavoriteFundCodes()
        return favoriteCodes.contains("\(fund.schemeCode)")
    }
    
    // MARK: - App Settings
    func saveAppData(email: String?, selectedFunds: Set<Fund>, filters: FundFilters) {
        if let email = email {
            saveUserEmail(email)
        }
        saveSelectedFunds(selectedFunds)
        saveFilters(filters)
    }
    
    func loadAppData() -> (email: String?, fundCodes: [String], filters: FundFilters) {
        let email = getUserEmail()
        let fundCodes = getSelectedFundCodes()
        let filters = getLastFilters()
        
        return (email: email, fundCodes: fundCodes, filters: filters)
    }
}

// MARK: - Extensions for AppState
extension AppState {
    func clearPersistedData() {
        DataPersistenceService.shared.clearUserData()
    }
}
