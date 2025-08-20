//
//  LoginView.swift
//  Rabbit Invest
//
//  Created by Kanav Nijhawan on 20/08/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isEmailFocused: Bool = false
    @State private var isPasswordFocused: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.primaryBackground,
                    AppColors.secondaryBackground
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // Logo and Title Section
                VStack(spacing: AppLayout.largePadding) {
                    // App Logo/Icon
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGreen)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.primaryBackground)
                    }
                    
                    // App Title
                    VStack(spacing: AppLayout.smallPadding) {
                        Text("Rabbit Invest")
                            .font(AppFonts.title)
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Your Smart Mutual Fund Companion")
                            .font(AppFonts.callout)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer(minLength: 20)
                
                // Modern Login Form
                VStack(spacing: AppLayout.largePadding) {
                    VStack(spacing: AppLayout.largePadding) {
                        // Email Field - iOS Style
                        VStack(alignment: .leading, spacing: AppLayout.smallPadding) {
                            Text("Email Address")
                                .font(AppFonts.callout.weight(.medium))
                                .foregroundColor(AppColors.secondaryText)
                            
                            TextField("Enter your email", text: $email)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.primaryText)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal, AppLayout.mediumPadding)
                                .padding(.vertical, 16)
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isEmailFocused ? AppColors.primaryGreen : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    isEmailFocused = true
                                    isPasswordFocused = false
                                }
                        }
                        
                        // Password Field - iOS Style
                        VStack(alignment: .leading, spacing: AppLayout.smallPadding) {
                            Text("Password")
                                .font(AppFonts.callout.weight(.medium))
                                .foregroundColor(AppColors.secondaryText)
                            
                            SecureField("Enter your password", text: $password)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.primaryText)
                                .padding(.horizontal, AppLayout.mediumPadding)
                                .padding(.vertical, 16)
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isPasswordFocused ? AppColors.primaryGreen : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    isPasswordFocused = true
                                    isEmailFocused = false
                                }
                        }
                    }
                    
                    // Error Message
                    if showError {
                        HStack(spacing: AppLayout.smallPadding) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.errorRed)
                                .font(.callout)
                            Text(errorMessage)
                                .font(AppFonts.callout)
                                .foregroundColor(AppColors.errorRed)
                            Spacer()
                        }
                        .padding(.horizontal, AppLayout.mediumPadding)
                        .padding(.vertical, AppLayout.smallPadding)
                        .background(AppColors.errorRed.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Modern Login Button
                    Button(action: handleLogin) {
                        HStack {
                            if appState.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryBackground))
                                    .scaleEffect(0.9)
                            } else {
                                Text("Login")
                                    .font(AppFonts.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(isFormValid && !appState.isLoading ? AppColors.primaryBackground : AppColors.tertiaryText)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(isFormValid && !appState.isLoading ? AppColors.primaryGreen : AppColors.borderColor)
                        )
                        .scaleEffect(isFormValid && !appState.isLoading ? 1.0 : 0.98)
                        .animation(.easeInOut(duration: 0.2), value: isFormValid)
                    }
                    .disabled(!isFormValid || appState.isLoading)
                }
                .padding(.horizontal, AppLayout.extraLargePadding)
                .padding(.vertical, AppLayout.largePadding)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppColors.secondaryBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, AppLayout.largePadding)
                
                Spacer(minLength: 20)
                
                // Additional Options - Outside the card for cleaner look
                VStack(spacing: AppLayout.mediumPadding) {
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.primaryGreen)
                    
                    HStack {
                        Text("Don't have an account?")
                            .font(AppFonts.callout)
                            .foregroundColor(AppColors.secondaryText)
                        
                        Button("Sign Up") {
                            // Handle sign up
                        }
                        .font(AppFonts.callout.weight(.medium))
                        .foregroundColor(AppColors.primaryGreen)
                    }
                }
                
                Spacer(minLength: 30)
                
                // Footer
                VStack(spacing: AppLayout.smallPadding) {
                    Text("Secure • Reliable • Fast")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.tertiaryText)
                    
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(AppColors.primaryGreen)
                        Text("Bank-level security")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.tertiaryText)
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 0)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return isValidEmail(email) && password.count >= 6
    }
    
    // MARK: - Functions
    private func handleLogin() {
        hideKeyboard()
        
        guard isValidEmail(email) else {
            showError(message: "Please enter a valid email address")
            return
        }
        
        guard password.count >= 6 else {
            showError(message: "Password must be at least 6 characters")
            return
        }
        
        appState.isLoading = true
        showError = false
        
        // Simulate login process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            appState.isLoading = false
            
            // For demo purposes, accept any valid email/password
            appState.login(email: email)
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isEmailFocused = false
        isPasswordFocused = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
