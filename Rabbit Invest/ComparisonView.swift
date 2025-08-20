

import SwiftUI
import Charts
import Combine

struct ComparisonView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var apiService = APIService.shared
    
    @State private var navDataMap: [String: [NAVData]] = [:]
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var selectedDataPoint: (fund: String, navData: NAVData)? = nil
    @State private var lastUpdateTime: Date = Date()
    @State private var autoRefreshTimer: Timer?
    @State private var chartScale: CGFloat = 1.0
    
    // Combine cancellables for API calls
    @State private var cancellables = Set<AnyCancellable>()
    
    // Time formatter for display
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        if appState.selectedFunds.isEmpty {
                            emptyStateView
                        } else {
                            ScrollView {
                                VStack(spacing: AppLayout.largePadding) {
                                    // NAV Chart
                                    navChartView
                                    
                                    // Fund Info Cards
                                    fundCardsView
                                }
                                .padding(.bottom, AppLayout.extraLargePadding)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("📊 ComparisonView appeared - Selected funds count: \(appState.selectedFunds.count)")
            print("📊 Current navDataMap keys: \(Array(navDataMap.keys))")
            if !appState.selectedFunds.isEmpty {
                print("📈 Selected funds: \(appState.selectedFunds.map { $0.schemeName })")
                print("📈 Selected scheme codes: \(appState.selectedFunds.map { $0.schemeCode })")
                loadNAVData()
                startAutoRefresh()
            } else {
                print("⚠️ No selected funds found!")
            }
        }
        .onDisappear {
            stopAutoRefresh()
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
                    // Favorites Button - with badge
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
                            appState.currentScreen = .fundSelection
                        }) {
                            Label("Browse Funds", systemImage: "magnifyingglass")
                        }
                        
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
            
            // Title and Selection Count
            HStack {
                VStack(alignment: .leading, spacing: AppLayout.extraSmallPadding) {
                    Text("Fund Comparison")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("\(appState.selectedFunds.count) funds selected")
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
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: AppLayout.largePadding) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryGreen))
                .scaleEffect(1.5)
            
            Text("Loading NAV data...")
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
            
            Text("Failed to load data")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primaryText)
            
            Text(error)
                .font(AppFonts.callout)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppLayout.largePadding)
            
            Button("Try Again") {
                loadNAVData()
            }
            .primaryButtonStyle()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AppLayout.largePadding) {
            Spacer()
            
            VStack(spacing: AppLayout.mediumPadding) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primaryGreen.opacity(0.6))
                
                Text("No Funds Selected")
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.primaryText)
                
                Text("Select funds from the fund list to compare their NAV performance")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.tertiaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, AppLayout.extraLargePadding)
            
            Button("Browse Funds") {
                appState.currentScreen = .fundSelection
            }
            .primaryButtonStyle()
            .padding(.horizontal, AppLayout.extraLargePadding)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - NAV Chart View
    private var navChartView: some View {
        VStack(spacing: 0) {
            chartTitleAndLegend
            chartContent
        }
        .cardStyle()
        .padding(.horizontal, AppLayout.largePadding)
    }
    
    private var chartTitleAndLegend: some View {
        VStack(spacing: AppLayout.smallPadding) {
            chartTitleSection
            chartLegendSection
        }
        .padding(AppLayout.largePadding)
    }
    
    private var chartTitleSection: some View {
        HStack {
            Text("NAV Trends")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            if let selectedPoint = selectedDataPoint {
                VStack(alignment: .trailing, spacing: AppLayout.extraSmallPadding) {
                    Text("₹\(selectedPoint.navData.nav)")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primaryGreen)
                    Text(selectedPoint.navData.date)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
    }
    
    private var chartLegendSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.mediumPadding) {
                ForEach(Array(appState.selectedFunds.enumerated()), id: \.element.id) { index, fund in
                    HStack(spacing: AppLayout.smallPadding) {
                        Circle()
                            .fill(AppColors.chartColors[index % AppColors.chartColors.count])
                            .frame(width: 12, height: 12)
                        
                        Text(fund.schemeName)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, AppLayout.smallPadding)
        }
    }
    
    private var chartContent: some View {
        basicChart
            .frame(height: 280)
            .chartXAxis { xAxisMarks }
            .chartYAxis { yAxisMarks }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 3600 * 24 * 30)
            .chartBackground { chartProxy in
                chartBackgroundView
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
            }
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.bottom, AppLayout.largePadding)
    }
    
    private var basicChart: some View {
        Chart {
            ForEach(Array(appState.selectedFunds.enumerated()), id: \.element.id) { index, fund in
                let schemeCodeKey = "\(fund.schemeCode)"
                let color = AppColors.chartColors[index % AppColors.chartColors.count]
                
                if let navData = navDataMap[schemeCodeKey] {
                    ForEach(Array(navData.prefix(20).enumerated()), id: \.offset) { dataIndex, data in
                        if let date = data.dateFormatted, let navValue = data.navValue {
                            LineMark(
                                x: .value("Date", date),
                                y: .value("NAV", navValue),
                                series: .value("Fund", "\(fund.schemeName)-\(index)")
                            )
                            .foregroundStyle(color)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", date),
                                y: .value("NAV", navValue)
                            )
                            .foregroundStyle(color)
                            .symbolSize(8)
                        }
                    }
                }
            }
        }
    }
    
    private var xAxisMarks: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(AppColors.dividerColor)
            AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(AppColors.tertiaryText)
            AxisValueLabel()
                .foregroundStyle(AppColors.tertiaryText)
                .font(AppFonts.caption2)
        }
    }
    
    private var yAxisMarks: some AxisContent {
        AxisMarks(position: .trailing) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(AppColors.dividerColor)
            AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(AppColors.tertiaryText)
            AxisValueLabel()
                .foregroundStyle(AppColors.tertiaryText)
                .font(AppFonts.caption2)
        }
    }
    
    private var chartBackgroundView: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            chartScale = max(1.0, min(3.0, value))
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if value < 1.0 {
                                    chartScale = 1.0
                                } else if value > 3.0 {
                                    chartScale = 3.0
                                }
                            }
                        }
                )
                .scaleEffect(chartScale)
        }
    }
    
    // MARK: - Fund Cards View
    private var fundCardsView: some View {
        VStack(spacing: AppLayout.mediumPadding) {
            HStack {
                Text("Fund Details")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, AppLayout.largePadding)
            
            ForEach(Array(appState.selectedFunds.enumerated()), id: \.element.id) { index, fund in
                FundInfoCard(
                    fund: fund,
                    color: AppColors.chartColors[index % AppColors.chartColors.count],
                    latestNAV: getLatestNAV(for: "\(fund.schemeCode)"),
                    navChange: getNAVChange(for: "\(fund.schemeCode)")
                )
                .environmentObject(appState)
                .padding(.horizontal, AppLayout.largePadding)
            }
        }
        .padding(.bottom, AppLayout.mediumPadding)
    }
    
    // MARK: - Chart Data Helper
    private func getAllChartData() -> [(fund: Fund, data: NAVData, color: Color)] {
        var allData: [(fund: Fund, data: NAVData, color: Color)] = []
        
        print("🔍 Chart data debug:")
        print("📊 Selected funds: \(appState.selectedFunds.count)")
        print("📊 NavDataMap keys: \(Array(navDataMap.keys))")
        
        for (index, fund) in Array(appState.selectedFunds.enumerated()) {
            let schemeCodeKey = "\(fund.schemeCode)"
            let color = AppColors.chartColors[index % AppColors.chartColors.count]
            
            print("🏦 Fund \(index): \(fund.schemeName)")
            print("🔑 Scheme code: \(schemeCodeKey)")
            
            if let navData = navDataMap[schemeCodeKey] {
                print("✅ Found NAV data: \(navData.count) points")
                
                let validData = navData.prefix(5) // Check first 5 points
                for (i, data) in validData.enumerated() {
                    print("📅 Point \(i): Date=\(data.date), NAV=\(data.nav)")
                    if let formattedDate = data.dateFormatted, let navValue = data.navValue {
                        print("✅ Parsed: Date=\(formattedDate), NAV=\(navValue)")
                    } else {
                        print("❌ Failed to parse date or NAV")
                    }
                }
                
                for data in navData.prefix(20).reversed() {
                    if data.dateFormatted != nil && data.navValue != nil {
                        allData.append((fund: fund, data: data, color: color))
                    }
                }
            } else {
                print("❌ No NAV data for scheme: \(schemeCodeKey)")
            }
        }
        
        print("📊 Total chart points: \(allData.count)")
        return allData
    }
    
    // MARK: - Helper Functions
    private func loadNAVData() {
        print("🚀 loadNAVData called - selectedFunds count: \(appState.selectedFunds.count)")
        guard !appState.selectedFunds.isEmpty else {
            print("❌ loadNAVData exiting - no selected funds")
            return
        }
        
        isLoading = true
        errorMessage = nil
        lastUpdateTime = Date()
        
        let schemeCodes = Array(appState.selectedFunds).map { "\($0.schemeCode)" }
        
        print("🔄 Fetching NAV data for schemes: \(schemeCodes)")
        print("🔄 About to call apiService.fetchNAVDataForFunds...")
        
        // Fetch real NAV data from API
        apiService.fetchNAVDataForFunds(schemeCodes)
            .sink(
                receiveCompletion: { completion in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        switch completion {
                        case .finished:
                            print("✅ NAV data fetch completed successfully")
                        case .failure(let error):
                            print("❌ NAV data fetch failed: \(error.localizedDescription)")
                            self.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { navResponseMap in
                    DispatchQueue.main.async {
                        print("📊 Received NAV data for \(navResponseMap.count) schemes")
                        print("📊 Response keys: \(Array(navResponseMap.keys))")
                        var tempNavDataMap: [String: [NAVData]] = [:]
                        for (schemeCode, response) in navResponseMap {
                            tempNavDataMap[schemeCode] = response.data
                            print("📈 Scheme \(schemeCode): \(response.data.count) data points")
                            if response.data.count > 0 {
                                let firstData = response.data[0]
                                print("📅 First data point - Date: \(firstData.date), NAV: \(firstData.nav)")
                                print("📅 Formatted date: \(firstData.dateFormatted?.description ?? "nil")")
                                print("📅 NAV value: \(firstData.navValue?.description ?? "nil")")
                            }
                        }
                        
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.navDataMap = tempNavDataMap
                        }
                        print("📊 Final navDataMap keys: \(Array(self.navDataMap.keys))")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func startAutoRefresh() {
        // Auto-refresh every 5 minutes (like CoinDCX)
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            loadNAVData()
        }
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    private func getLatestNAV(for schemeCode: String) -> String? {
        return navDataMap[schemeCode]?.first?.nav
    }
    
    private func getNAVChange(for schemeCode: String) -> (value: Double, percentage: Double)? {
        guard let navData = navDataMap[schemeCode],
              navData.count >= 2,
              let latestNAV = navData[0].navValue,
              let previousNAV = navData[1].navValue else {
            return nil
        }
        
        let change = latestNAV - previousNAV
        let percentage = (change / previousNAV) * 100
        
        return (value: change, percentage: percentage)
    }
    
    // MARK: - Chart Interaction
    private func handleChartTap(at location: CGPoint, geometry: GeometryProxy, chartProxy: ChartProxy) {
        // Handle tapping on chart to show NAV + Date
        print("📊 Chart tapped at: \(location)")
        // Implementation for showing NAV and date on tap can be added here
    }
}

// MARK: - Fund Info Card
struct FundInfoCard: View {
    let fund: Fund
    let color: Color
    let latestNAV: String?
    let navChange: (value: Double, percentage: Double)?
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: AppLayout.mediumPadding) {
            // Header with Fund Name and Color Indicator
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(fund.schemeName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(2)
                
                Spacer()
            }
            
            // Fund Details Grid
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
                        Text("₹\(latestNAV ?? "N/A")")
                            .font(AppFonts.callout.weight(.semibold))
                            .foregroundColor(AppColors.primaryGreen)
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
                    
                    if let change = navChange {
                        VStack(alignment: .trailing, spacing: AppLayout.extraSmallPadding) {
                            Text("Daily Change")
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.tertiaryText)
                            
                            HStack(spacing: AppLayout.extraSmallPadding) {
                                Image(systemName: change.percentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption)
                                
                                Text(String(format: "%.2f%%", abs(change.percentage)))
                                    .font(AppFonts.callout.weight(.semibold))
                            }
                            .foregroundColor(change.percentage >= 0 ? AppColors.successGreen : AppColors.errorRed)
                        }
                    }
                }
                
                Divider()
                    .background(AppColors.dividerColor)
                
                HStack {
                    VStack(alignment: .leading, spacing: AppLayout.extraSmallPadding) {
                        Text("AMC")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.tertiaryText)
                        Text(fund.amc ?? "N/A")
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
        }
        .padding(AppLayout.mediumPadding)
        .cardStyle()
    }
}

// MARK: - Preview
struct ComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ComparisonView()
            .environmentObject({
                let appState = AppState()
                appState.selectedFunds = Set([
                    Fund(schemeCode: 120503, schemeName: "Sample Fund 1", isinGrowth: "INF123456789", isinDivReinvestment: nil),
                    Fund(schemeCode: 120504, schemeName: "Sample Fund 2", isinGrowth: "INF987654321", isinDivReinvestment: nil)
                ])
                return appState
            }())
    }
}
