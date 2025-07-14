//
//  HandleInputSheet.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct HandleInputSheet: View {
    @Binding var handleInput: String
    let onSubmit: () -> Void
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var localInput: String = ""
    @State private var isPresented = false
    @State private var isValidating = false
    @State private var validationPassed = false
    @State private var showContinueOption = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dungeon-style background
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    // Hero Section
                    VStack(spacing: 32) {
                        // Animated Title
                        VStack(spacing: 16) {
                            Text("⚔️")
                                .font(.system(size: 80))
                                .scaleEffect(isPresented ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPresented)
                            
                            VStack(spacing: 8) {
                                Text("Enter the Arena")
                                    .font(.custom("TTPhobosTrial-Bold", size: 32))
                                    .foregroundColor(colorThemeManager.current.text)
                                    .multilineTextAlignment(.center)
                                
                                Text("Connect your Codeforces profile to begin your quest")
                                    .font(.custom("TTPhobosTrial-Regular", size: 16))
                                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        
                        // Input Section
                        VStack(spacing: 24) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Codeforces Handle")
                                        .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                                        .foregroundColor(colorThemeManager.current.text)
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(colorThemeManager.current.accent)
                                    
                                    TextField("Enter your handle", text: $localInput)
                                        .font(.custom("TTPhobosTrial-Regular", size: 16))
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(colorThemeManager.current.text)
                                        .focused($isTextFieldFocused)
                                        .onSubmit {
                                            if !localInput.isEmpty && !cfService.isLoading {
                                                submitHandle()
                                            }
                                        }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(colorThemeManager.current.tabBar.opacity(0.8))
                                        .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Status Display
                            if isValidating {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(colorThemeManager.current.accent)
                                    
                                    Text("Validating handle...")
                                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                                        .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(colorThemeManager.current.accent.opacity(0.1))
                                        .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                                )
                            } else if validationPassed {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    
                                    Text("Handle verified! Ready to start your quest.")
                                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.green.opacity(0.1))
                                        .stroke(.green.opacity(0.3), lineWidth: 1)
                                )
                            } else if let error = cfService.error {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Validation failed")
                                            .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.red.opacity(0.1))
                                        .stroke(.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Action Button
                            Button(action: submitHandle) {
                                HStack(spacing: 12) {
                                    if isValidating {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else if validationPassed {
                                        Image(systemName: "checkmark.shield.fill")
                                            .font(.title2)
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title2)
                                    }
                                    
                                    Text(getButtonText())
                                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            isButtonEnabled ? 
                                            colorThemeManager.current.accent : 
                                            colorThemeManager.current.text.opacity(0.3)
                                        )
                                )
                            }
                            .disabled(!isButtonEnabled)
                            
                            // Continue anyway option after validation timeout
                            if showContinueOption && !validationPassed {
                                Button(action: continueAnyway) {
                                    HStack(spacing: 8) {
                                        Text("Continue anyway")
                                            .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                                        Text("(validation taking too long)")
                                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                                    }
                                    .foregroundColor(colorThemeManager.current.text.opacity(0.8))
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Helper Text
                        VStack(spacing: 8) {
                            Text("💡 Example: tourist, Benq, Errichto")
                                .font(.custom("TTPhobosTrial-Regular", size: 14))
                                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            
                            Text("Don't worry - you can update this later in settings!")
                                .font(.custom("TTPhobosTrial-Regular", size: 12))
                                .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                    
                    // Skip Option
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Skip for now")
                            .font(.custom("TTPhobosTrial-Regular", size: 16))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            .underline()
                    }
                    .padding(.bottom, 40)
                }
            }
            .onChange(of: localInput) { newValue in
                handleInput = newValue
            }
            .onAppear {
                localInput = handleInput
                isTextFieldFocused = true
                isPresented = true
            }
        }
    }
    
    private var isButtonEnabled: Bool {
        let trimmed = localInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !isValidating
    }
    
    private func getButtonText() -> String {
        if isValidating {
            return "Validating..."
        } else if validationPassed {
            return "Start Quest ⚔️"
        } else {
            return "Continue to Arena"
        }
    }
    
    private func continueAnyway() {
        let trimmedHandle = localInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHandle.isEmpty else { return }
        
        // Save handle to UserDefaults
        UserDefaults.standard.savedHandle = trimmedHandle
        handleInput = trimmedHandle
        
        // Continue to app
        onSubmit()
    }
    
    private func submitHandle() {
        let trimmedHandle = localInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHandle.isEmpty else { return }
        
        // Save handle immediately to UserDefaults
        UserDefaults.standard.savedHandle = trimmedHandle
        handleInput = trimmedHandle
        
        // Start validation in background
        isValidating = true
        validationPassed = false
        showContinueOption = false
        
        // Show continue option after 5 seconds if validation is still running
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isValidating {
                showContinueOption = true
            }
        }
        
        Task {
            await cfService.fetchUserInfo(handle: trimmedHandle)
            
            await MainActor.run {
                isValidating = false
                
                if cfService.currentUser != nil {
                    validationPassed = true
                    // Wait a moment to show success, then continue
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onSubmit()
                    }
                } else if !showContinueOption {
                    // If validation failed but we haven't shown continue option yet, show it
                    showContinueOption = true
                }
            }
        }
    }
}

#Preview {
    HandleInputSheet(handleInput: .constant("")) {
        print("Handle submitted")
    }
    .environmentObject(ColorThemeManager())
}


