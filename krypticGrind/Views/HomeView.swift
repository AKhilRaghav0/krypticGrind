//
//  HomeView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingHandleInput = false
    @State private var handleInput = ""
    @State private var showingSettingsSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Error handling with retry
                        if let error = cfService.error {
                            ErrorBannerView(
                                message: error,
                                isLoading: cfService.isLoading,
                                onRetry: {
                                    Task {
                                        await cfService.retryLastOperation()
                                    }
                                }
                            )
                        }
                        
                        if let user = cfService.currentUser {
                            // User Profile Section
                            ModernUserProfileCard(user: user)
                            
                            // Quick Stats Grid
                            ModernStatsGrid()
                            
                            // Today's Progress
                            ModernProgressCard()
                            
                            // Recent Activity
                            ModernActivityCard()
                            
                        } else if !cfService.isLoading {
                            // Welcome Section
                            ModernWelcomeCard {
                                showingHandleInput = true
                            }
                        }
                        
                        // Loading State
                        if cfService.isLoading {
                            ModernLoadingView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await cfService.refreshData()
                }
            }
            .navigationTitle("KrypticGrind")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if cfService.currentUser != nil {
                        Button(action: {
                            Task {
                                await cfService.refreshData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHandleInput) {
                HandleInputSheet(handleInput: $handleInput) {
                    Task {
                        await cfService.fetchAllUserData(handle: handleInput)
                    }
                    showingHandleInput = false
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .task {
                if let savedHandle = UserDefaults.standard.savedHandle {
                    await cfService.fetchAllUserData(handle: savedHandle)
                }
            }
        }
    }
}

// MARK: - Modern User Profile Card
struct ModernUserProfileCard: View {
    let user: CFUser
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with avatar and basic info
            HStack(spacing: 16) {
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
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("@\(user.handle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(user.rank)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.ratingColor(for: user.rating), in: Capsule())
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Rating stats
            HStack(spacing: 0) {
                StatColumn(
                    title: "Current",
                    value: "\(user.rating)",
                    color: Color.ratingColor(for: user.rating)
                )
                
                Divider()
                    .frame(height: 40)
                
                StatColumn(
                    title: "Max",
                    value: "\(user.maxRating)",
                    color: Color.ratingColor(for: user.maxRating)
                )
                
                Divider()
                    .frame(height: 40)
                
                StatColumn(
                    title: "Contribution",
                    value: "\(user.contribution)",
                    color: user.contribution >= 0 ? .green : .red
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatColumn: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Stats Grid
struct ModernStatsGrid: View {
    @StateObject private var cfService = CFService.shared
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ModernStatCard(
                title: "Contests",
                value: "\(cfService.ratingHistory.count)",
                icon: "trophy.fill",
                color: .orange
            )
            
            ModernStatCard(
                title: "Submissions",
                value: "\(cfService.recentSubmissions.count)",
                icon: "doc.text.fill",
                color: .blue
            )
            
            ModernStatCard(
                title: "Accepted",
                value: "\(cfService.recentSubmissions.acceptedSubmissions().count)",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    init(title: String, value: String, icon: String, color: Color, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .scaleEffect(1.1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
            
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Modern Progress Card
struct ModernProgressCard: View {
    @StateObject private var cfService = CFService.shared
    
    var body: some View {
        let todaysSubmissions = cfService.recentSubmissions.todaysSubmissions()
        let todaysAccepted = todaysSubmissions.acceptedSubmissions()
        let dailyGoal = UserDefaults.standard.dailyGoal
        let progress = Double(todaysAccepted.count) / Double(dailyGoal)
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(todaysAccepted.count) of \(dailyGoal) problems solved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if progress >= 1.0 {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: progress)
                }
            }
            
            // Modern progress bar
            ProgressView(value: progress) {
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .progressViewStyle(.linear)
            .tint(.blue)
            .scaleEffect(y: 1.5)
            
            HStack {
                Label("\(todaysSubmissions.count) submissions today", systemImage: "paperplane.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if progress >= 1.0 {
                    Text("Goal achieved! 🎉")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                } else {
                    Text("\(dailyGoal - todaysAccepted.count) more to go")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Modern Activity Card
struct ModernActivityCard: View {
    @StateObject private var cfService = CFService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                NavigationLink(destination: SubmissionsView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(cfService.recentSubmissions.prefix(4)) { submission in
                    ModernSubmissionRow(submission: submission)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ModernSubmissionRow: View {
    let submission: CFSubmission
    
    var body: some View {
        HStack(spacing: 12) {
            // Verdict indicator
            Circle()
                .fill(Color.verdictColor(for: submission.verdict ?? ""))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(submission.problem.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("\(submission.problem.index) • \(submission.programmingLanguage)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(submission.verdictDisplayText)
                    .font(.caption.bold())
                    .foregroundStyle(Color.verdictColor(for: submission.verdict ?? ""))
                
                Text(submission.submissionDate.timeAgo())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Welcome Card
struct WelcomeCard: View {
    @State private var showingHandleInput = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.colors.accent)
                .shadow(color: themeManager.colors.accent.opacity(0.6), radius: 10)
            
            Text("Welcome to KrypticGrind")
                .font(.largeTitle.bold())
                .foregroundColor(themeManager.colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Track your Codeforces journey with style. Enter your handle to get started.")
                .font(.body)
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingHandleInput = true
            }) {
                Text("Get Started")
                    .font(.headline.bold())
                    .foregroundColor(themeManager.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.colors.accent)
                    .cornerRadius(12)
                    .shadow(color: themeManager.colors.accent.opacity(0.6), radius: 10)
            }
        }
        .padding(30)
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingHandleInput) {
            HandleInputSheet(handleInput: .constant("")) {
                // Handle submission
                showingHandleInput = false
            }
        }
    }
}

// MARK: - Error Retry View for Home
struct ErrorRetryHomeView: View {
    let message: String
    let isLoading: Bool
    let onRetry: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(themeManager.colors.warning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Connection Issue")
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onRetry) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.colors.textPrimary))
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(themeManager.colors.accent)
                }
            }
            .disabled(isLoading)
        }
        .padding()
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Modern Loading View
struct ModernLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading your data...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Error Banner View
struct ErrorBannerView: View {
    let message: String
    let isLoading: Bool
    let onRetry: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isLoading)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Modern Welcome Card
struct ModernWelcomeCard: View {
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 8) {
                Text("Welcome to KrypticGrind")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text("Track your competitive programming journey")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text("Get Started")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.gradient)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - AI Suggestions Integration
struct SimplifiedAISuggestionsCard: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var suggestions: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("AI Coach Suggestions", systemImage: "brain.head.profile")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating personalized suggestions...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if suggestions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    Text("AI-powered suggestions")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text("Get personalized recommendations based on your coding patterns")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Get Suggestions") {
                        generateSuggestions()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 16)
                            
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button("Refresh Suggestions") {
                        generateSuggestions()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            if suggestions.isEmpty && cfService.currentUser != nil {
                generateSuggestions()
            }
        }
    }
    
    private func generateSuggestions() {
        guard let user = cfService.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                let apiKey = "AIzaSyAA6sSSrUYbfHZePNn0TH2abg8XoSiwuYs"
                let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=\(apiKey)")!
                
                let prompt = createPromptForUser(user)
                let requestBody = [
                    "contents": [
                        [
                            "parts": [
                                ["text": prompt]
                            ]
                        ]
                    ],
                    "generationConfig": [
                        "temperature": 0.7,
                        "topK": 40,
                        "topP": 0.95,
                        "maxOutputTokens": 1024
                    ]
                ]
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let candidates = response?["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    
                    let parsedSuggestions = parseGeminiResponse(text)
                    
                    await MainActor.run {
                        self.suggestions = parsedSuggestions
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.suggestions = getDefaultSuggestions()
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.suggestions = getDefaultSuggestions()
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createPromptForUser(_ user: CFUser) -> String {
        return """
        You are an AI assistant for competitive programming. Based on this user profile, provide exactly 3 short, actionable suggestions (each 10-15 words max):
        
        User: \(user.handle)
        Rating: \(user.rating)
        Max Rating: \(user.maxRating)
        Submissions: \(cfService.recentSubmissions.count) recent
        
        Format your response as a simple list:
        1. [suggestion]
        2. [suggestion]
        3. [suggestion]
        
        Focus on practical advice for improving competitive programming skills.
        """
    }
    
    private func parseGeminiResponse(_ text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var suggestions: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.starts(with: "1.") || trimmed.starts(with: "2.") || trimmed.starts(with: "3.") {
                let suggestion = trimmed.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
                if !suggestion.isEmpty {
                    suggestions.append(String(suggestion))
                }
            }
        }
        
        return suggestions.isEmpty ? getDefaultSuggestions() : Array(suggestions.prefix(3))
    }
    
    private func getDefaultSuggestions() -> [String] {
        return [
            "Practice dynamic programming problems to improve algorithmic thinking",
            "Focus on implementation problems to build coding speed and accuracy",
            "Study graph algorithms - they appear frequently in contests"
        ]
    }
}

#Preview {
    HomeView()
}
