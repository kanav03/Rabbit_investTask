//
//  APIService.swift
//  Rabbit Invest
//
//  Created by Kanav Nijhawan on 20/08/25.
//

import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://api.mfapi.in"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Fetch All Mutual Funds
    func fetchAllFunds() -> AnyPublisher<[Fund], Error> {
        guard let url = URL(string: "\(baseURL)/mf") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Fund].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Fetch NAV Data for Specific Fund
    func fetchNAVData(for schemeCode: String) -> AnyPublisher<NAVResponse, Error> {
        guard let url = URL(string: "\(baseURL)/mf/\(schemeCode)") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map { output in
                print("🌐 Received data for scheme \(schemeCode): \(output.data.count) bytes")
                return output.data
            }
            .decode(type: NAVResponse.self, decoder: JSONDecoder())
            .map { response in
                print("✅ Successfully decoded NAV response for scheme \(schemeCode): \(response.data.count) data points")
                return response
            }
            .catch { error -> AnyPublisher<NAVResponse, Error> in
                print("❌ Decoding error for scheme \(schemeCode): \(error)")
                return Fail(error: error).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Fetch NAV Data for Multiple Funds
    func fetchNAVDataForFunds(_ schemeCodes: [String]) -> AnyPublisher<[String: NAVResponse], Error> {
        let publishers = schemeCodes.map { schemeCode in
            fetchNAVData(for: schemeCode)
                .map { navResponse in (schemeCode, navResponse) }
                .catch { _ in Empty<(String, NAVResponse), Never>() }
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { Dictionary(uniqueKeysWithValues: $0) }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Search Funds
    func searchFunds(query: String, from allFunds: [Fund]) -> [Fund] {
        guard !query.isEmpty else { return allFunds }
        
        let lowercasedQuery = query.lowercased()
        return allFunds.filter { fund in
            fund.schemeName.lowercased().contains(lowercasedQuery) ||
            fund.fundHouse?.lowercased().contains(lowercasedQuery) == true ||
            fund.schemeCategory?.lowercased().contains(lowercasedQuery) == true ||
            fund.amc?.lowercased().contains(lowercasedQuery) == true
        }
    }
    
    // MARK: - Filter Funds
    func filterFunds(funds: [Fund], with filters: FundFilters) -> [Fund] {
        var filteredFunds = funds
        
        // Search filter
        if !filters.searchText.isEmpty {
            filteredFunds = searchFunds(query: filters.searchText, from: filteredFunds)
        }
        
        // AMC filter
        if !filters.selectedAMC.isEmpty {
            filteredFunds = filteredFunds.filter { fund in
                fund.amc?.lowercased() == filters.selectedAMC.lowercased()
            }
        }
        
        // Category filter
        if !filters.selectedCategory.isEmpty {
            filteredFunds = filteredFunds.filter { fund in
                fund.schemeCategory?.lowercased() == filters.selectedCategory.lowercased()
            }
        }
        
        // Type filter
        if !filters.selectedType.isEmpty {
            filteredFunds = filteredFunds.filter { fund in
                fund.schemeType?.lowercased() == filters.selectedType.lowercased()
            }
        }
        
        return filteredFunds
    }
    
    // MARK: - Get Unique Values for Filters
    func getUniqueAMCs(from funds: [Fund]) -> [String] {
        let amcs = funds.compactMap { $0.amc }.filter { !$0.isEmpty }
        return Array(Set(amcs)).sorted()
    }
    
    func getUniqueCategories(from funds: [Fund]) -> [String] {
        let categories = funds.compactMap { $0.schemeCategory }.filter { !$0.isEmpty }
        return Array(Set(categories)).sorted()
    }
    
    func getUniqueTypes(from funds: [Fund]) -> [String] {
        let types = funds.compactMap { $0.schemeType }.filter { !$0.isEmpty }
        return Array(Set(types)).sorted()
    }
}

// MARK: - Error Handling
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Data for Development
//extension APIService {
////    func getMockFunds() -> [Fund] {
////        return [
////            Fund(schemeCode: "120503", schemeName: "Aditya Birla Sun Life Tax Relief 96 - Growth", fundHouse: "Aditya Birla Sun Life Mutual Fund", schemeType: "Open Ended Schemes", schemeCategory: "ELSS", amc: "Aditya Birla Sun Life AMC Limited"),
////            Fund(schemeCode: "120504", schemeName: "Aditya Birla Sun Life Frontline Equity Fund - Growth", fundHouse: "Aditya Birla Sun Life Mutual Fund", schemeType: "Open Ended Schemes", schemeCategory: "Large Cap Fund", amc: "Aditya Birla Sun Life AMC Limited"),
////            Fund(schemeCode: "120505", schemeName: "Aditya Birla Sun Life Top 100 Fund - Growth", fundHouse: "Aditya Birla Sun Life Mutual Fund", schemeType: "Open Ended Schemes", schemeCategory: "Large Cap Fund", amc: "Aditya Birla Sun Life AMC Limited"),
////            Fund(schemeCode: "118989", schemeName: "ICICI Prudential Bluechip Fund - Growth", fundHouse: "ICICI Prudential Mutual Fund", schemeType: "Open Ended Schemes", schemeCategory: "Large Cap Fund", amc: "ICICI Prudential Asset Management Company Limited")
////        ]
////    }
//    
////    func getMockNAVData(for schemeCode: String) -> NAVResponse {
////        let sampleData = [
////            NAVData(date: "20-08-2024", nav: "580.45"),
////            NAVData(date: "19-08-2024", nav: "578.32"),
////            NAVData(date: "18-08-2024", nav: "582.10"),
////            NAVData(date: "17-08-2024", nav: "579.87"),
////            NAVData(date: "16-08-2024", nav: "585.23")
////        ]
////        
////        let meta = NAVMeta(
////            fundHouse: "Sample Fund House",
////            schemeType: "Open Ended Schemes",
////            schemeCategory: "Large Cap Fund",
////            schemeCode: schemeCode,
////            schemeName: "Sample Fund Name"
////        )
////        
////        return NAVResponse(meta: meta, data: sampleData, status: "SUCCESS")
////    }
//}
