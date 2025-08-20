//
//  Models.swift
//  Rabbit Invest
//
//  Created by Kanav Nijhawan on 20/08/25.
//

import Foundation

// MARK: - User Model
struct User {
    let email: String
    var selectedFunds: [String] = [] // Store scheme codes
    var searchHistory: [String] = []
    var lastFilters: FundFilters = FundFilters()
}

// MARK: - Fund Models
struct Fund: Codable, Identifiable, Hashable {
    let id = UUID()
    let schemeCode: Int
    let schemeName: String
    let isinGrowth: String?
    let isinDivReinvestment: String?
    
    // Computed properties for backward compatibility
    var fundHouse: String? { 
        // Extract fund house from scheme name - improved logic
        let name = schemeName.uppercased()
        
        // Common AMC patterns
        if name.contains("HDFC") { return "HDFC" }
        if name.contains("ICICI") { return "ICICI Prudential" }
        if name.contains("SBI") { return "SBI" }
        if name.contains("AXIS") { return "Axis" }
        if name.contains("KOTAK") { return "Kotak" }
        if name.contains("NIPPON") { return "Nippon India" }
        if name.contains("ADITYA BIRLA") { return "Aditya Birla Sun Life" }
        if name.contains("MIRAE") { return "Mirae Asset" }
        if name.contains("DSP") { return "DSP" }
        if name.contains("FRANKLIN") { return "Franklin Templeton" }
        if name.contains("INVESCO") { return "Invesco" }
        if name.contains("UTI") { return "UTI" }
        if name.contains("TATA") { return "Tata" }
        if name.contains("BAJAJ") { return "Bajaj Finserv" }
        if name.contains("GROWW") { return "Groww" }
        if name.contains("BANDHAN") { return "Bandhan" }
        if name.contains("MOTILAL") { return "Motilal Oswal" }
        if name.contains("CANARA") { return "Canara Robeco" }
        if name.contains("EDELWEISS") { return "Edelweiss" }
        if name.contains("LIC") { return "LIC MF" }
        if name.contains("BARODA") { return "Baroda BNP Paribas" }
        if name.contains("MAHINDRA") { return "Mahindra Manulife" }
        if name.contains("SUNDARAM") { return "Sundaram" }
        if name.contains("UNION") { return "Union" }
        if name.contains("PGIM") { return "PGIM India" }
        if name.contains("HSBC") { return "HSBC" }
        if name.contains("JM ") { return "JM Financial" }
        if name.contains("QUANT ") { return "Quant" }
        if name.contains("SAMCO") { return "Samco" }
        if name.contains("SHRIRAM") { return "Shriram" }
        
        // Fallback to first word
        let components = schemeName.components(separatedBy: " ")
        return components.first
    }
    
    var schemeType: String? {
        let name = schemeName.uppercased()
        if name.contains("ETF") { return "ETF" }
        if name.contains("INDEX") { return "Index Fund" }
        if name.contains("DEBT") || name.contains("GILT") || name.contains("LIQUID") || name.contains("DURATION") { return "Debt Fund" }
        if name.contains("ARBITRAGE") { return "Arbitrage Fund" }
        if name.contains("ELSS") || name.contains("TAX") { return "ELSS" }
        if name.contains("OVERNIGHT") { return "Overnight Fund" }
        if name.contains("MONEY MARKET") { return "Money Market Fund" }
        return "Equity Fund" // Default
    }
    
    var schemeCategory: String? {
        let name = schemeName.uppercased()
        if name.contains("LARGE CAP") { return "Large Cap" }
        if name.contains("MID CAP") { return "Mid Cap" }
        if name.contains("SMALL CAP") { return "Small Cap" }
        if name.contains("MULTI CAP") { return "Multi Cap" }
        if name.contains("FLEXI CAP") { return "Flexi Cap" }
        if name.contains("FOCUSED") { return "Focused Fund" }
        if name.contains("VALUE") { return "Value Fund" }
        if name.contains("CONTRA") { return "Contra Fund" }
        if name.contains("SECTOR") || name.contains("BANKING") || name.contains("PHARMA") || name.contains("IT") || name.contains("INFRASTRUCTURE") || name.contains("ENERGY") || name.contains("CONSUMPTION") || name.contains("HEALTHCARE") || name.contains("FINANCIAL") { return "Sectoral/Thematic" }
        if name.contains("INTERNATIONAL") || name.contains("GLOBAL") { return "International Fund" }
        if name.contains("HYBRID") || name.contains("BALANCED") { return "Hybrid Fund" }
        return "Diversified Equity" // Default
    }
    
    var amc: String? { fundHouse }
    
    private enum CodingKeys: String, CodingKey {
        case schemeCode
        case schemeName
        case isinGrowth
        case isinDivReinvestment
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(schemeCode)
    }
    
    static func == (lhs: Fund, rhs: Fund) -> Bool {
        lhs.schemeCode == rhs.schemeCode
    }
}

struct FundData: Codable {
    let meta: FundMeta
    let data: [Fund]
}

struct FundMeta: Codable {
    let fundHouse: String
    let schemeType: String
    let schemeCategory: String
    let schemeCode: String
    let schemeName: String
    
    private enum CodingKeys: String, CodingKey {
        case fundHouse = "fund_house"
        case schemeType = "scheme_type"
        case schemeCategory = "scheme_category"
        case schemeCode = "scheme_code"
        case schemeName = "scheme_name"
    }
}

// MARK: - NAV Models
struct NAVResponse: Codable {
    let meta: NAVMeta
    let data: [NAVData]
    let status: String
}

struct NAVMeta: Codable {
    let fundHouse: String
    let schemeType: String
    let schemeCategory: String
    let schemeCode: Int
    let schemeName: String
    let isinGrowth: String?
    let isinDivReinvestment: String?
    
    private enum CodingKeys: String, CodingKey {
        case fundHouse = "fund_house"
        case schemeType = "scheme_type"
        case schemeCategory = "scheme_category"
        case schemeCode = "scheme_code"
        case schemeName = "scheme_name"
        case isinGrowth = "isin_growth"
        case isinDivReinvestment = "isin_div_reinvestment"
    }
}

struct NAVData: Codable, Identifiable {
    let date: String
    let nav: String
    
    // Use date as stable ID
    var id: String { date }
    
    var dateFormatted: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: date)
    }
    
    var navValue: Double? {
        return Double(nav)
    }
    
    private enum CodingKeys: String, CodingKey {
        case date, nav
    }
}

// MARK: - Filter Models
struct FundFilters {
    var searchText: String = ""
    var selectedAMC: String = ""
    var selectedCategory: String = ""
    var selectedType: String = ""
}

// MARK: - App State
enum AppScreen {
    case login
    case fundSelection
    case comparison
    case favorites
}

class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .login
    @Published var user: User? = nil
    @Published var selectedFunds: Set<Fund> = []
    @Published var favoriteFunds: Set<Fund> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let persistenceService = DataPersistenceService.shared
    
    init() {
        loadDataFromPersistence()
    }
    
    var canShowComparison: Bool {
        selectedFunds.count >= 2 && selectedFunds.count <= 4
    }
    
    func login(email: String) {
        user = User(email: email)
        currentScreen = .fundSelection
        persistenceService.saveUserEmail(email)
    }
    
    func logout() {
        // Save current state before logging out
        saveDataToPersistence()
        
        user = nil
        selectedFunds.removeAll()
        currentScreen = .login
        
        // Clear user-specific data but keep app preferences
        persistenceService.clearUserData()
    }
    
    func selectFund(_ fund: Fund) {
        if selectedFunds.count < 4 {
            selectedFunds.insert(fund)
            saveSelectedFunds()
        }
    }
    
    func deselectFund(_ fund: Fund) {
        selectedFunds.remove(fund)
        saveSelectedFunds()
    }
    
    func toggleFundSelection(_ fund: Fund) {
        if selectedFunds.contains(fund) {
            deselectFund(fund)
        } else {
            selectFund(fund)
        }
    }
    
    // MARK: - Persistence Methods
    private func saveSelectedFunds() {
        persistenceService.saveSelectedFunds(selectedFunds)
    }
    
    func saveDataToPersistence() {
        persistenceService.saveAppData(
            email: user?.email,
            selectedFunds: selectedFunds,
            filters: FundFilters() // This would be passed from FundSelectionView in a real implementation
        )
    }
    
    func loadDataFromPersistence() {
        let persistedData = persistenceService.loadAppData()
        
        // Don't auto-login, but could pre-fill email field
        if let email = persistedData.email {
            // Store email for potential pre-filling in login form
            // but don't automatically log in for security
        }
        
        // Selected funds will be restored when fund data is loaded
        // in FundSelectionView using the persisted fund codes
    }
    
    func restoreSelectedFunds(from allFunds: [Fund]) {
        let persistedCodes = persistenceService.getSelectedFundCodes()
        let restoredFunds = allFunds.filter { fund in
            persistedCodes.contains("\(fund.schemeCode)")
        }
        selectedFunds = Set(restoredFunds)
    }
    
    // MARK: - Favorites Management
    func addToFavorites(_ fund: Fund) -> Bool {
        let success = persistenceService.addToFavorites(fund)
        if success {
            favoriteFunds.insert(fund)
        }
        return success
    }
    
    func removeFromFavorites(_ fund: Fund) {
        persistenceService.removeFromFavorites(fund)
        favoriteFunds.remove(fund)
    }
    
    func toggleFavorite(_ fund: Fund) -> Bool {
        if isFavorite(fund) {
            removeFromFavorites(fund)
            return false
        } else {
            return addToFavorites(fund)
        }
    }
    
    func isFavorite(_ fund: Fund) -> Bool {
        return persistenceService.isFavorite(fund)
    }
    
    func restoreFavoriteFunds(from allFunds: [Fund]) {
        let favoriteCodes = persistenceService.getFavoriteFundCodes()
        let restoredFavorites = allFunds.filter { fund in
            favoriteCodes.contains("\(fund.schemeCode)")
        }
        favoriteFunds = Set(restoredFavorites)
    }
    
    var canAddMoreFavorites: Bool {
        return favoriteFunds.count < 5
    }
}
