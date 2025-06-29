//
//  AISuggestionsView.swift
//  KrypticGrind
//
//  Created by akhil on 01/07/25.
//

import SwiftUI

struct AISuggestionsView: View {
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var showingAppearanceSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                if geminiService.isLoading {
                    LoadingView()
                } else if let error = geminiService.error {
                    ErrorView(error: error) {
                        await generateSuggestions()
                    }
                } else if geminiService.suggestions.isEmpty {
                    EmptyAISuggestionsView {
                        await generateSuggestions()
                    }
                } else {
                    SuggestionsListView(suggestions: geminiService.suggestions)
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task { await generateSuggestions() }
                        }) {
                            Label("Refresh Suggestions", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            showingAppearanceSettings = true
                        }) {
                            Label("Appearance", systemImage: "paintbrush")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(themeManager.colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAppearanceSettings) {
                ThemeSelectorSheet()
            }
        }
        .task {
            if geminiService.suggestions.isEmpty {
                await generateSuggestions()
            }
        }
    }
    
    private func generateSuggestions() async {
        let userStats = createUserStats()
        await geminiService.generateSuggestions(
            userStats: userStats,
            submissions: cfService.recentSubmissions,
            user: cfService.currentUser
        )
    }
    
    private func createUserStats() -> UserStats {
        let totalSubmissions = cfService.recentSubmissions.count
        let acceptedSubmissions = cfService.recentSubmissions.filter { $0.isAccepted }.count
        let acceptanceRate = totalSubmissions > 0 ? Double(acceptedSubmissions) / Double(totalSubmissions) * 100 : 0
        
        let languageStats = Dictionary(grouping: cfService.recentSubmissions) { $0.programmingLanguage }
            .mapValues { $0.count }
        let mostUsedLanguage = languageStats.max(by: { $0.value < $1.value })?.key ?? "None"
        
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let weeklySubmissions = cfService.recentSubmissions.filter { $0.submissionDate >= weekAgo }.count
        
        let tagStats = cfService.recentSubmissions.flatMap { $0.problem.tags }
            .reduce(into: [String: Int]()) { counts, tag in counts[tag, default: 0] += 1 }
        let topTopics = Array(tagStats.sorted { $0.value > $1.value }.prefix(3).map { $0.key })
        
        return UserStats(
            totalSubmissions: totalSubmissions,
            acceptedSubmissions: acceptedSubmissions,
            acceptanceRate: acceptanceRate,
            mostUsedLanguage: mostUsedLanguage,
            currentStreak: calculateStreak(),
            weeklySubmissions: weeklySubmissions,
            topTopics: topTopics,
            recentPerformance: calculateRecentPerformance()
        )
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for _ in 0..<30 {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let hasSubmission = cfService.recentSubmissions.contains { submission in
                let submissionDate = calendar.startOfDay(for: submission.submissionDate)
                return submissionDate >= currentDate && submissionDate < nextDate
            }
            
            if hasSubmission {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateRecentPerformance() -> String {
        let lastWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let recentSubmissions = cfService.recentSubmissions.filter { $0.submissionDate >= lastWeek }
        let recentAccepted = recentSubmissions.filter { $0.isAccepted }.count
        
        if recentSubmissions.isEmpty {
            return "No recent activity"
        }
        
        let recentAcceptanceRate = Double(recentAccepted) / Double(recentSubmissions.count) * 100
        
        if recentAcceptanceRate >= 70 {
            return "Excellent performance this week!"
        } else if recentAcceptanceRate >= 50 {
            return "Good performance this week"
        } else {
            return "Room for improvement this week"
        }
    }
}

// MARK: - Suggestions List View
struct SuggestionsListView: View {
    let suggestions: [AISuggestion]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundStyle(themeManager.colors.accent.gradient)
                        
                        Text("AI Coach Recommendations")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        
                        Spacer()
                    }
                    
                    Text("Personalized suggestions to boost your competitive programming skills")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Priority Suggestions
                let highPrioritySuggestions = suggestions.filter { $0.priority == .high }
                if !highPrioritySuggestions.isEmpty {
                    SuggestionSection(
                        title: "High Priority",
                        subtitle: "Focus on these first",
                        suggestions: highPrioritySuggestions,
                        accentColor: .red
                    )
                }
                
                // Medium Priority Suggestions
                let mediumPrioritySuggestions = suggestions.filter { $0.priority == .medium }
                if !mediumPrioritySuggestions.isEmpty {
                    SuggestionSection(
                        title: "Recommended",
                        subtitle: "Great opportunities for growth",
                        suggestions: mediumPrioritySuggestions,
                        accentColor: .orange
                    )
                }
                
                // Low Priority Suggestions
                let lowPrioritySuggestions = suggestions.filter { $0.priority == .low }
                if !lowPrioritySuggestions.isEmpty {
                    SuggestionSection(
                        title: "Consider Later",
                        subtitle: "When you have extra time",
                        suggestions: lowPrioritySuggestions,
                        accentColor: .blue
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Suggestion Section
struct SuggestionSection: View {
    let title: String
    let subtitle: String
    let suggestions: [AISuggestion]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(accentColor.gradient)
                    .frame(width: 8, height: 8)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(suggestions, id: \.id) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
        }
    }
}

// MARK: - Suggestion Card
struct SuggestionCard: View {
    let suggestion: AISuggestion
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(suggestion.type.color).opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: suggestion.type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(suggestion.type.color))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Text(suggestion.priority.displayText)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(priorityColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(priorityColor)
                        
                        Text(suggestion.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Description
            Text(suggestion.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            // Action Button
            Button(action: {
                if let urlString = suggestion.actionURL,
                   let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: suggestion.actionURL != nil ? "safari" : "checkmark")
                        .font(.subheadline.weight(.medium))
                    
                    Text(suggestion.actionText)
                        .font(.subheadline.weight(.medium))
                    
                    Spacer()
                    
                    if suggestion.actionURL != nil {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(suggestion.type.color).gradient, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var priorityColor: Color {
        switch suggestion.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated AI Brain
            ZStack {
                Circle()
                    .stroke(themeManager.colors.accent.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(themeManager.colors.accent.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30))
                    .foregroundStyle(themeManager.colors.accent)
            }
            
            VStack(spacing: 8) {
                Text("AI Coach is thinking...")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text("Analyzing your performance to create personalized recommendations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Empty AI Suggestions View
struct EmptyAISuggestionsView: View {
    let onRefresh: () async -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(themeManager.colors.accent.gradient)
                
                VStack(spacing: 8) {
                    Text("AI Coach Ready")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Get personalized recommendations to improve your competitive programming skills")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Button(action: {
                Task { await onRefresh() }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Get AI Suggestions")
                        .font(.headline.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(themeManager.colors.accent.gradient, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: String
    let onRetry: () async -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
                
                VStack(spacing: 8) {
                    Text("Oops!")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Button(action: {
                Task { await onRetry() }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                        .font(.headline.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(themeManager.colors.accent.gradient, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NavigationView {
        AISuggestionsView()
    }
}
