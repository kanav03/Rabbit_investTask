//
//  Theme.swift
//  Rabbit Invest
//
//  Created by Kanav Nijhawan on 20/08/25.
//

import SwiftUI

// MARK: - Color Theme
struct AppColors {
    // Primary Colors - Professional MFD Black & Green Theme
    static let primaryBackground = Color.black
    static let secondaryBackground = Color(red: 0.05, green: 0.05, blue: 0.05) // Very dark gray
    static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark gray
    
    // Green Accent Colors - Professional Financial Green
    static let primaryGreen = Color(red: 0.0, green: 0.8, blue: 0.4) // Bright professional green
    static let secondaryGreen = Color(red: 0.0, green: 0.6, blue: 0.3) // Darker green
    static let lightGreen = Color(red: 0.0, green: 0.9, blue: 0.5) // Light accent green
    static let successGreen = Color(red: 0.0, green: 0.7, blue: 0.3) // Success state green
    
    // Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.8, green: 0.8, blue: 0.8) // Light gray
    static let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6) // Medium gray
    static let placeholderText = Color(red: 0.4, green: 0.4, blue: 0.4) // Dark gray
    
    // Chart Colors for Multiple Funds - Better contrast for comparison
    static let chartColors: [Color] = [
        primaryGreen,                           // Green
        Color(red: 0.0, green: 0.48, blue: 1.0),  // Blue
        Color(red: 1.0, green: 0.58, blue: 0.0),  // Orange
        Color(red: 0.88, green: 0.19, blue: 0.42), // Pink/Red
        Color(red: 0.68, green: 0.32, blue: 0.87), // Purple
        Color(red: 0.0, green: 0.74, blue: 0.83)   // Cyan
    ]
    
    // Status Colors
    static let errorRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    // Border and Divider Colors
    static let borderColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let dividerColor = Color(red: 0.15, green: 0.15, blue: 0.15)
}

// MARK: - Typography
struct AppFonts {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.medium)
    static let title3 = Font.title3.weight(.medium)
    static let headline = Font.headline.weight(.semibold)
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let caption2 = Font.caption2
}

// MARK: - Spacing and Layout
struct AppLayout {
    static let extraSmallPadding: CGFloat = 4
    static let smallPadding: CGFloat = 8
    static let mediumPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
    static let extraLargePadding: CGFloat = 32
    
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let cardCornerRadius: CGFloat = 16
    
    static let borderWidth: CGFloat = 1
    static let thickBorderWidth: CGFloat = 2
}

// MARK: - Custom View Modifiers
struct PrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDisabled ? AppColors.tertiaryText : AppColors.primaryBackground)
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.vertical, AppLayout.mediumPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .fill(isDisabled ? AppColors.borderColor : AppColors.primaryGreen)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppColors.primaryGreen)
            .padding(.horizontal, AppLayout.largePadding)
            .padding(.vertical, AppLayout.mediumPadding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColors.primaryGreen, lineWidth: AppLayout.borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .fill(AppColors.cardBackground)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
    }
}

struct InputFieldModifier: ViewModifier {
    let isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(AppLayout.mediumPadding)
            .background(AppColors.secondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(isFocused ? AppColors.primaryGreen : AppColors.borderColor, 
                           lineWidth: isFocused ? AppLayout.thickBorderWidth : AppLayout.borderWidth)
            )
            .cornerRadius(AppLayout.cornerRadius)
    }
}

// MARK: - View Extensions
extension View {
    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isDisabled: isDisabled))
    }
    
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
    
    func inputFieldStyle(isFocused: Bool = false) -> some View {
        self.modifier(InputFieldModifier(isFocused: isFocused))
    }
}
