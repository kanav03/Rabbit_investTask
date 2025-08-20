//
//  FiltersView.swift
//  Rabbit Invest
//
//  Created by Kanav Nijhawan on 20/08/25.
//

import SwiftUI

struct FiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: FundFilters
    
    let availableAMCs: [String]
    let availableCategories: [String]
    let availableTypes: [String]
    let onApply: () -> Void
    
    @State private var tempFilters: FundFilters
    @State private var searchAMC: String = ""
    @State private var searchCategory: String = ""
    @State private var searchType: String = ""
    
    init(filters: Binding<FundFilters>, availableAMCs: [String], availableCategories: [String], availableTypes: [String], onApply: @escaping () -> Void) {
        self._filters = filters
        self.availableAMCs = availableAMCs
        self.availableCategories = availableCategories
        self.availableTypes = availableTypes
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if !tempFilters.selectedAMC.isEmpty { count += 1 }
        if !tempFilters.selectedCategory.isEmpty { count += 1 }
        if !tempFilters.selectedType.isEmpty { count += 1 }
        return count
    }
    
    var body: some View {
        ZStack {
            AppColors.primaryBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                headerView
                
                // Content
                ScrollView {
                    LazyVStack(spacing: AppLayout.extraLargePadding) {
                        // Filter Summary
                        if activeFiltersCount > 0 {
                            filterSummaryCard
                        }
                        
                        // AMC Filter
                        ModernFilterSection(
                            title: "Fund House",
                            icon: "building.2",
                            selectedValue: $tempFilters.selectedAMC,
                            searchText: $searchAMC,
                            options: availableAMCs,
                            placeholder: "Select fund house"
                        )
                        
                        // Category Filter
                        ModernFilterSection(
                            title: "Category",
                            icon: "chart.pie",
                            selectedValue: $tempFilters.selectedCategory,
                            searchText: $searchCategory,
                            options: availableCategories,
                            placeholder: "Select category"
                        )
                        
                        // Type Filter
                        ModernFilterSection(
                            title: "Fund Type",
                            icon: "list.bullet.rectangle",
                            selectedValue: $tempFilters.selectedType,
                            searchText: $searchType,
                            options: availableTypes,
                            placeholder: "Select fund type"
                        )
                    }
                    .padding(AppLayout.largePadding)
                    .padding(.bottom, 100) // Space for bottom bar
                }
                
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(AppColors.primaryText)
                        .frame(width: 44, height: 44)
                        .background(AppColors.cardBackground)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Title
                VStack(spacing: 2) {
                    Text("Filters")
                        .font(AppFonts.title2.weight(.bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    if activeFiltersCount > 0 {
                        Text("\(activeFiltersCount) active")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.primaryGreen)
                    }
                }
                
                Spacer()
                
                // Clear All Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tempFilters = FundFilters()
                        searchAMC = ""
                        searchCategory = ""
                        searchType = ""
                    }
                }) {
                    Text("Clear")
                        .font(AppFonts.subheadline.weight(.semibold))
                        .foregroundColor(activeFiltersCount > 0 ? AppColors.errorRed : AppColors.tertiaryText)
                        .frame(width: 44, height: 44)
                }
                .disabled(activeFiltersCount == 0)
            }
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.vertical, AppLayout.mediumPadding)
            
            Divider()
                .background(AppColors.dividerColor)
        }
        .background(AppColors.secondaryBackground)
    }
    
    private var filterSummaryCard: some View {
        VStack(alignment: .leading, spacing: AppLayout.mediumPadding) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.primaryGreen)
                    .font(.title3)
                
                Text("Active Filters")
                    .font(AppFonts.headline.weight(.semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Text("\(activeFiltersCount)")
                    .font(AppFonts.caption.weight(.bold))
                    .foregroundColor(AppColors.primaryGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.primaryGreen.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            FlowLayout(spacing: AppLayout.smallPadding) {
                if !tempFilters.selectedAMC.isEmpty {
                    filterTag(title: tempFilters.selectedAMC, type: "Fund House") {
                        tempFilters.selectedAMC = ""
                    }
                }
                
                if !tempFilters.selectedCategory.isEmpty {
                    filterTag(title: tempFilters.selectedCategory, type: "Category") {
                        tempFilters.selectedCategory = ""
                    }
                }
                
                if !tempFilters.selectedType.isEmpty {
                    filterTag(title: tempFilters.selectedType, type: "Type") {
                        tempFilters.selectedType = ""
                    }
                }
            }
        }
        .padding(AppLayout.largePadding)
        .background(AppColors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.primaryGreen.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(16)
    }
    
    private func filterTag(title: String, type: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: AppLayout.smallPadding) {
            VStack(alignment: .leading, spacing: 2) {
                Text(type)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.tertiaryText)
                Text(title)
                    .font(AppFonts.caption.weight(.medium))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.horizontal, AppLayout.mediumPadding)
        .padding(.vertical, AppLayout.smallPadding)
        .background(AppColors.secondaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.borderColor, lineWidth: 0.5)
        )
        .cornerRadius(8)
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.dividerColor)
            
            HStack(spacing: AppLayout.mediumPadding) {
                Button("Reset All") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tempFilters = FundFilters()
                        searchAMC = ""
                        searchCategory = ""
                        searchType = ""
                    }
                }
                .font(AppFonts.body.weight(.semibold))
                .foregroundColor(AppColors.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(AppColors.borderColor, lineWidth: 1)
                )
                .cornerRadius(25)
                
                Button("Apply Filters") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        filters = tempFilters
                        onApply()
                        dismiss()
                    }
                }
                .font(AppFonts.body.weight(.semibold))
                .foregroundColor(AppColors.primaryBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.primaryGreen)
                .cornerRadius(25)
                .scaleEffect(activeFiltersCount > 0 ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.2), value: activeFiltersCount)
            }
            .padding(AppLayout.largePadding)
            .background(AppColors.secondaryBackground)
        }
    }
}

struct ModernFilterSection: View {
    let title: String
    let icon: String
    @Binding var selectedValue: String
    @Binding var searchText: String
    let options: [String]
    let placeholder: String
    
    @State private var isExpanded: Bool = false
    
    var filteredOptions: [String] {
        if searchText.isEmpty {
            return options
        } else {
            return options.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.mediumPadding) {
            // Section Header
            HStack(spacing: AppLayout.mediumPadding) {
                HStack(spacing: AppLayout.smallPadding) {
                    Image(systemName: icon)
                        .foregroundColor(AppColors.primaryGreen)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                    
                    Text(title)
                        .font(AppFonts.title3.weight(.semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                Spacer()
                
                if !selectedValue.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedValue = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.secondaryText)
                            .font(.title3)
                    }
                }
            }
            
            // Selected Value Display / Trigger
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(selectedValue.isEmpty ? placeholder : selectedValue)
                        .font(AppFonts.body)
                        .foregroundColor(selectedValue.isEmpty ? AppColors.placeholderText : AppColors.primaryText)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(AppColors.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
                .padding(AppLayout.largePadding)
                .background(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isExpanded ? AppColors.primaryGreen : AppColors.borderColor, lineWidth: isExpanded ? 2 : 1)
                )
                .cornerRadius(12)
            }
            
            // Expanded Options
            if isExpanded {
                VStack(spacing: 0) {
                    // Search Bar (if many options)
                    if options.count > 6 {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.tertiaryText)
                                .font(.callout)
                            
                            TextField("Search \(title.lowercased())...", text: $searchText)
                                .font(AppFonts.body)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(AppLayout.mediumPadding)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(8)
                        .padding(.bottom, AppLayout.smallPadding)
                    }
                    
                    // Options List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredOptions, id: \.self) { option in
                                OptionRow(
                                    option: option,
                                    isSelected: selectedValue == option,
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedValue = option
                                            searchText = ""
                                            isExpanded = false
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding(AppLayout.largePadding)
                .background(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.primaryGreen.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(12)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .onChange(of: selectedValue) { _ in
            if !selectedValue.isEmpty && isExpanded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded = false
                    searchText = ""
                }
            }
        }
    }
}

struct OptionRow: View {
    let option: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(option)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.primaryGreen)
                        .font(.title3)
                }
            }
            .padding(.vertical, AppLayout.mediumPadding)
            .padding(.horizontal, AppLayout.smallPadding)
            .background(
                isSelected ? AppColors.primaryGreen.opacity(0.1) : Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// FlowLayout for flexible tag arrangement
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
}

struct FlowResult {
    var size = CGSize.zero
    var frames: [CGRect] = []
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var currentRow = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > maxWidth && currentX > 0 {
                // Move to next row
                currentRow += 1
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            frames.append(CGRect(x: currentX, y: currentY, width: subviewSize.width, height: subviewSize.height))
            
            currentX += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
        
        size = CGSize(width: maxWidth, height: currentY + rowHeight)
    }
}

#Preview {
    FiltersView(
        filters: .constant(FundFilters()),
        availableAMCs: ["HDFC", "ICICI Prudential", "SBI", "Axis", "Kotak", "Nippon India", "Aditya Birla Sun Life", "Mirae Asset", "DSP", "Franklin Templeton"],
        availableCategories: ["Large Cap", "Mid Cap", "Small Cap", "Multi Cap", "Flexi Cap", "Sectoral/Thematic", "Diversified Equity"],
        availableTypes: ["Equity Fund", "Debt Fund", "ETF", "Index Fund", "ELSS", "Hybrid Fund"],
        onApply: {}
    )
    .preferredColorScheme(.dark)
}
