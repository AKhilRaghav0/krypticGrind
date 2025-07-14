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
                            
                            // Action Button
                            Button(action: submitHandle) {
                                HStack(spacing: 12) {
                                    if cfService.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "checkmark.shield.fill")
                                            .font(.title2)
                                    }
                                    
                                    Text(cfService.isLoading ? "Validating..." : "Start Quest")
                                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            localInput.isEmpty || cfService.isLoading ? 
                                            colorThemeManager.current.text.opacity(0.3) : 
                                            colorThemeManager.current.accent
                                        )
                                )
                            }
                            .disabled(localInput.isEmpty || cfService.isLoading)
                        }
                        .padding(.horizontal, 32)
                        
                        // Helper Text
                        VStack(spacing: 8) {
                            Text("💡 Example: tourist, Benq, Errichto")
                                .font(.custom("TTPhobosTrial-Regular", size: 14))
                                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            
                            Text("We'll fetch your submissions and stats to power AI recommendations")
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
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(colorThemeManager.current.tabBar)
            .cornerRadius(12)
            .foregroundColor(colorThemeManager.current.text)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

struct KrypticTextFieldStyle: TextFieldStyle {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(colorThemeManager.current.tabBar)
            .cornerRadius(12)
            .foregroundColor(colorThemeManager.current.text)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

// --- SectionHeader helper ---
struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// --- SettingsRow helper ---
struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    var value: String? = nil
    let content: () -> Content
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.body)
            Spacer()
            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
            }
            content()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}

// --- Refactored SettingsSheet ---
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
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
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Card
                    SectionHeader(title: "Profile")
                    HStack(spacing: 16) {
                        if let avatarURL = cfService.currentUser?.avatar, let url = URL(string: avatarURL) {
                            AsyncImage(url: url, transaction: .init(animation: .default)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 56, height: 56)
                                case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                case .failure:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 56)
                                        .foregroundColor(.secondary)
                                @unknown default:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 56)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .id(url)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .foregroundColor(.secondary)
                                }
                        VStack(alignment: .leading) {
                            Text(cfService.currentUser?.displayName ?? "Akhil Raghav")
                                .font(.title3.bold())
                            Text("@" + (cfService.currentUser?.handle ?? "KrypticBit"))
                                    .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        Spacer()
                        Button("Change") { showingHandleChange = true }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                // Appearance Section
                    SectionHeader(title: "Appearance")
                    VStack(spacing: 12) {
                        SettingsRow(icon: "paintbrush.fill", title: "Theme", value: "Current Theme") {
                            Button("Change") { showingThemeSelector = true }
                        .buttonStyle(.bordered)
                        }
                        SettingsRow(icon: systemImageForAppearanceMode, title: "Appearance Mode", value: displayNameForAppearanceMode) {
                            Button("Change") { showingAppearanceSettings = true }
                        .buttonStyle(.bordered)
                        }
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                // Preferences Section
                    SectionHeader(title: "Preferences")
                    VStack(spacing: 12) {
                        SettingsRow(icon: "target", title: "Daily Goal") {
                            Stepper("", value: $dailyGoal, in: 1...20)
                            .labelsHidden()
                    }
                        SettingsRow(icon: "bell.fill", title: "Notifications") {
                            Toggle("", isOn: $showNotifications)
                                .labelsHidden()
                        }
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                
                // About Section
                    SectionHeader(title: "About")
                    VStack(spacing: 12) {
                        SettingsRow(icon: "info.circle.fill", title: "Version", value: "1.0.0") { EmptyView() }
                        SettingsRow(icon: "heart.fill", title: "Made with 💜", value: "KrypticVerse") { EmptyView() }
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    }
                .padding(.vertical)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingHandleChange) {
                HandleChangeSheet(currentHandle: newHandle) { handle in
                    Task { await cfService.fetchAllUserData(handle: handle) }
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
    @EnvironmentObject var colorThemeManager: ColorThemeManager
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
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Update") {
                            submitHandle()
                        }
                        .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 12)
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


