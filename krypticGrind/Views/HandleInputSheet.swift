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
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var localInput: String = ""
    @State private var isPresented = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                        .scaleEffect(isPresented ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPresented)
                    
                    VStack(spacing: 12) {
                        Text("Enter Your Codeforces Handle")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("We'll fetch your profile and track your competitive programming journey")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 20) {
                    TextField("e.g., tourist", text: $localInput)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            if !localInput.isEmpty && !cfService.isLoading {
                                submitHandle()
                            }
                        }
                        .onChange(of: localInput) { newValue in
                            handleInput = newValue
                        }
                    
                    if let error = cfService.error {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button(action: submitHandle) {
                        HStack(spacing: 8) {
                            if cfService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "arrow.right")
                            }
                            
                            Text(cfService.isLoading ? "Loading..." : "Continue")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isButtonEnabled ? .blue : .gray, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                    }
                    .disabled(!isButtonEnabled)
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
        return !trimmed.isEmpty && !cfService.isLoading
    }
    
    private func submitHandle() {
        let trimmedHandle = localInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHandle.isEmpty else { return }
        
        handleInput = trimmedHandle
        
        Task {
            await cfService.fetchUserInfo(handle: trimmedHandle)
            if cfService.currentUser != nil {
                await MainActor.run {
                    onSubmit()
                }
            }
        }
    }
}

struct ThemedTextFieldStyle: TextFieldStyle {
    @StateObject private var themeManager = ThemeManager.shared
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(themeManager.colors.surface)
            .cornerRadius(12)
            .foregroundColor(themeManager.colors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.colors.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

struct KrypticTextFieldStyle: TextFieldStyle {
    @StateObject private var themeManager = ThemeManager.shared
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(themeManager.colors.surface)
            .cornerRadius(12)
            .foregroundColor(themeManager.colors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.colors.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Settings Sheet
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingHandleChange = false
    @State private var showingThemeSelector = false
    @State private var showingAppearanceSettings = false
    @State private var newHandle: String = ""
    @AppStorage("daily_goal") private var dailyGoal: Int = 3
    @AppStorage("show_notifications") private var showNotifications: Bool = true
    
    private var systemImageForAppearanceMode: String {
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "is_dark_mode") != nil {
            let isDark = userDefaults.bool(forKey: "is_dark_mode")
            return isDark ? "moon.fill" : "sun.max.fill"
        } else {
            return "circle.lefthalf.filled"
        }
    }
    
    private var displayNameForAppearanceMode: String {
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "is_dark_mode") != nil {
            let isDark = userDefaults.bool(forKey: "is_dark_mode") 
            return isDark ? "Dark" : "Light"
        } else {
            return "System"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section("Profile") {
                    HStack(spacing: 16) {
                        if let user = cfService.currentUser {
                            AsyncImage(url: URL(string: user.avatar)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(.quaternary)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.secondary)
                                    }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(.quaternary)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.secondary)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let user = cfService.currentUser {
                                Text(user.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("@\(user.handle)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Not signed in")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Tap to add your handle")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Change") {
                            newHandle = cfService.currentUser?.handle ?? ""
                            showingHandleChange = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 8)
                }
                
                // Appearance Section
                Section("Appearance") {
                    HStack {
                        Label("Theme", systemImage: "paintbrush.fill")
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(themeManager.currentTheme.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                            Text(themeManager.currentTheme.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Change") {
                            showingThemeSelector = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        Label("Appearance Mode", systemImage: systemImageForAppearanceMode)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(displayNameForAppearanceMode)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                            Text("Light, Dark, or System")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Change") {
                            showingAppearanceSettings = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
                
                // Preferences Section
                Section("Preferences") {
                    HStack {
                        Label("Daily Goal", systemImage: "target")
                        
                        Spacer()
                        
                        Stepper("\(dailyGoal) problems", value: $dailyGoal, in: 1...20)
                            .labelsHidden()
                    }
                    
                    Toggle(isOn: $showNotifications) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Made with 💜", systemImage: "heart.fill")
                        Spacer()
                        Text("KrypticVerse")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingHandleChange) {
                HandleChangeSheet(currentHandle: newHandle) { handle in
                    Task {
                        await cfService.fetchAllUserData(handle: handle)
                    }
                    showingHandleChange = false
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingThemeSelector) {
                ThemeSelectorSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingAppearanceSettings) {
                ThemeSelectorSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Handle Change Sheet
struct HandleChangeSheet: View {
    let currentHandle: String
    let onSubmit: (String) -> Void
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var newHandle: String = ""
    @State private var isPresented = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 20) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                        .scaleEffect(isPresented ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPresented)
                    
                    VStack(spacing: 12) {
                        Text("Change Codeforces Handle")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        
                        Text("Enter your new Codeforces handle to update your profile")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if !currentHandle.isEmpty {
                            HStack(spacing: 8) {
                                Text("Current:")
                                    .foregroundStyle(.secondary)
                                Text("@\(currentHandle)")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                VStack(spacing: 20) {
                    TextField("New handle", text: $newHandle)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            if !newHandle.isEmpty && !cfService.isLoading {
                                submitHandle()
                            }
                        }
                    
                    if let error = cfService.error {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button(action: submitHandle) {
                            HStack(spacing: 8) {
                                if cfService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "checkmark")
                                }
                                
                                Text(cfService.isLoading ? "Updating..." : "Update")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isButtonEnabled ? .blue : .gray, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                        }
                        .disabled(!isButtonEnabled)
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Change Handle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                newHandle = currentHandle
                isTextFieldFocused = true
                isPresented = true
            }
        }
    }
    
    private var isButtonEnabled: Bool {
        let trimmed = newHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != currentHandle && !cfService.isLoading
    }
    
    private func submitHandle() {
        let trimmedHandle = newHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHandle.isEmpty && trimmedHandle != currentHandle else { return }
        
        Task {
            await cfService.fetchUserInfo(handle: trimmedHandle)
            if cfService.currentUser != nil {
                await MainActor.run {
                    onSubmit(trimmedHandle)
                }
            }
        }
    }
}

#Preview {
    HandleInputSheet(handleInput: .constant("")) {
        print("Handle submitted")
    }
}


