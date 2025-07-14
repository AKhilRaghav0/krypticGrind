//
//  DungeonPracticeView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI
import Charts

struct DungeonPracticeView: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var geminiService = GeminiService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var selectedQuest: QuestType = .tags
    
    enum QuestType: String, CaseIterable {
        case tags = "Skill Trees"
        case languages = "Weapon Mastery"
        case verdicts = "Battle Results"
        case difficulty = "Challenge Levels"
        
        var icon: String {
            switch self {
            case .tags: return "🌳"
            case .languages: return "⚔️"
            case .verdicts: return "🛡️"
            case .difficulty: return "🏔️"
            }
        }
        
        var dungeonDescription: String {
            switch self {
            case .tags: return "Master different algorithm disciplines"
            case .languages: return "Perfect your coding weapons"
            case .verdicts: return "Analyze your combat performance"
            case .difficulty: return "Conquer increasingly difficult challenges"
            }
        }
    }
    
    // MARK: - Computed Properties for Live Data
    private var dailySolvedCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return cfService.recentSubmissions.filter { submission in
            submission.isAccepted && 
            Calendar.current.startOfDay(for: submission.submissionDate) == today
        }.count
    }
    
    private var weeklySolvedCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return cfService.recentSubmissions.filter { submission in
            submission.isAccepted && submission.submissionDate >= weekAgo
        }.count
    }
    
    private var currentStreak: Int {
        let submissions = cfService.recentSubmissions
            .filter { $0.isAccepted }
            .sorted { $0.submissionDate > $1.submissionDate }
        
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for submission in submissions {
            let submissionDate = Calendar.current.startOfDay(for: submission.submissionDate)
            if submissionDate == currentDate {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else if submissionDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    private var weakestTopics: [String] {
        let acceptedSubmissions = cfService.recentSubmissions.filter { $0.isAccepted }
        let allTags = acceptedSubmissions.flatMap { $0.problem.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 }).mapValues { $0.count }
        
        let sortedTags = tagCounts.sorted { $0.value < $1.value }
        return Array(sortedTags.prefix(3).map { $0.key })
    }
    
    private var recentDifficultyRange: String {
        let recentSubmissions = cfService.recentSubmissions
            .filter { $0.isAccepted }
            .prefix(20)
        
        let ratings = recentSubmissions.compactMap { $0.problem.rating }
        
        if ratings.isEmpty { return "No rated problems" }
        
        let minRating = ratings.min() ?? 0
        let maxRating = ratings.max() ?? 0
        
        return "\(minRating) - \(maxRating)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quest Selector
                QuestSelector(selectedQuest: $selectedQuest)
                    .padding(.horizontal, 20)
                
                // Main Analytics Chart
                DungeonAnalyticsCard(questType: selectedQuest)
                    .padding(.horizontal, 20)
                
                // Stats Grid
                DungeonStatsGrid()
                    .padding(.horizontal, 20)
                
                // Current Objectives
                CurrentObjectivesCard(
                    dailySolved: dailySolvedCount,
                    weeklySolved: weeklySolvedCount,
                    currentStreak: currentStreak
                )
                    .padding(.horizontal, 20)
                
                // Skill Progression
                SkillProgressionCard(
                    weakestTopics: weakestTopics,
                    difficultyRange: recentDifficultyRange,
                    cfService: cfService,
                    geminiService: geminiService
                )
                    .padding(.horizontal, 20)
                
                // Combat History
                CombatHistoryCard(cfService: cfService)
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 100)
            }
            .padding(.top, 12)
        }
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchUserSubmissions(handle: handle, count: 200)
                
                // Also fetch user info if not available
                if cfService.currentUser == nil {
                    await cfService.fetchUserInfo(handle: handle)
                }
                
                // Generate AI suggestions based on user data
                if !cfService.recentSubmissions.isEmpty {
                    let acceptedSubmissions = cfService.recentSubmissions.filter { $0.isAccepted }
                    let totalSubmissions = cfService.recentSubmissions.count
                    let acceptanceRate = totalSubmissions > 0 ? Double(acceptedSubmissions.count) / Double(totalSubmissions) * 100 : 0
                    let mostUsedLanguage = Dictionary(grouping: cfService.recentSubmissions, by: { $0.programmingLanguage })
                        .max(by: { $0.value.count < $1.value.count })?.key ?? "Unknown"
                    let topTopics = Array(Dictionary(grouping: acceptedSubmissions) { $0.problem.tags.first ?? "unknown" }
                        .sorted { $0.value.count > $1.value.count }
                        .prefix(3)
                        .map { $0.key })
                    
                    await geminiService.generateSuggestions(
                        userStats: UserStats(
                            totalSubmissions: totalSubmissions,
                            acceptedSubmissions: acceptedSubmissions.count,
                            acceptanceRate: acceptanceRate,
                            mostUsedLanguage: mostUsedLanguage,
                            currentStreak: currentStreak,
                            weeklySubmissions: weeklySolvedCount,
                            topTopics: topTopics,
                            recentPerformance: "Recent performance analysis"
                        ),
                        submissions: cfService.recentSubmissions,
                        user: cfService.currentUser
                    )
                }
            }
        }
    }
}

// MARK: - Quest Selector
struct QuestSelector: View {
    @Binding var selectedQuest: DungeonPracticeView.QuestType
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(DungeonPracticeView.QuestType.allCases, id: \.self) { quest in
                    QuestTab(
                        quest: quest,
                        isSelected: selectedQuest == quest,
                        action: {
                            selectedQuest = quest
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }
}

struct QuestTab: View {
    let quest: DungeonPracticeView.QuestType
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                action()
            }
        }) {
            VStack(spacing: 8) {
                Text(quest.icon)
                    .font(.system(size: isSelected ? 22 : 20))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                VStack(spacing: 4) {
                    Text(quest.rawValue)
                        .font(.custom("TTPhobosTrial-Bold", size: isSelected ? 15 : 14))
                        .foregroundColor(
                            isSelected ? colorThemeManager.current.text : colorThemeManager.current.text.opacity(0.7)
                        )
                    
                    Text(quest.dungeonDescription)
                        .font(.custom("TTPhobosTrial-Regular", size: 10))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            isSelected ? 
                            colorThemeManager.current.tabBar : 
                            colorThemeManager.current.tabBar.opacity(0.5)
                        )
                    
                    if isSelected {
                        // Glass effect overlay for selected tab
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorThemeManager.current.tabBar.opacity(0.3),
                                        colorThemeManager.current.tabBar.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                colorThemeManager.current.accent.opacity(0.4),
                                                colorThemeManager.current.accent.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .overlay(
                                // Glass shine
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: .white.opacity(0.2), location: 0),
                                                .init(color: .white.opacity(0.05), location: 0.3),
                                                .init(color: .clear, location: 0.7),
                                                .init(color: .white.opacity(0.05), location: 1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: colorThemeManager.current.accent.opacity(0.2), radius: 8, x: 0, y: 2)
                    } else {
                        // Simple border for unselected
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(colorThemeManager.current.accent.opacity(0.1), lineWidth: 0.5)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0), value: isSelected)
    }
}

// MARK: - Dungeon Analytics Card
struct DungeonAnalyticsCard: View {
    let questType: DungeonPracticeView.QuestType
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(questType.icon + " " + questType.rawValue)
                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Text("Battle Analytics")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundColor(colorThemeManager.current.accent)
            }
            
            // Chart Content
            if cfService.recentSubmissions.isEmpty {
                VStack(spacing: 12) {
                    Text("🗡️")
                        .font(.system(size: 40))
                    
                    Text("No battles recorded yet")
                        .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Text("Start solving problems to see your combat analytics")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
            } else {
                // Chart based on quest type
                Group {
                    switch questType {
                    case .tags:
                        SkillTreeChart()
                    case .languages:
                        WeaponMasteryChart()
                    case .verdicts:
                        BattleResultsChart()
                            .padding(.bottom, 8) // Extra padding for Battle Results
                    case .difficulty:
                        ChallengeLevelChart()
                    }
                }
                .frame(minHeight: 180)
                .padding(.bottom, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

// MARK: - Charts
struct SkillTreeChart: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var tagData: [(String, Int)] {
        let acceptedSubmissions = cfService.recentSubmissions.filter { $0.isAccepted }
        let tagCounts = Dictionary(grouping: acceptedSubmissions) { submission in
            submission.problem.tags.first ?? "Unknown"
        }.mapValues { $0.count }
        
        return Array(tagCounts.sorted { $0.value > $1.value }.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(tagData.enumerated()), id: \.offset) { index, data in
                HStack(spacing: 12) {
                    Text(getSkillIcon(for: data.0))
                        .font(.system(size: 18))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.0.capitalized)
                            .font(.custom("TTPhobosTrial-DemiBold", size: 15))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text("\(data.1) victories")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Progress bar
                    GeometryReader { geometry in
                        let maxCount = tagData.first?.1 ?? 1
                        let progress = Double(data.1) / Double(maxCount)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorThemeManager.current.text.opacity(0.1))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(getSkillColor(for: index))
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                    }
                    .frame(width: 60, height: 8)
                    
                    Text("\(data.1)")
                        .font(.custom("TTPhobosTrial-Bold", size: 14))
                        .foregroundColor(getSkillColor(for: index))
                        .frame(minWidth: 24, alignment: .trailing)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Returns an emoji icon representing the given problem tag.
    /// - Parameter tag: The problem tag to map to an icon.
    /// - Returns: An emoji string corresponding to the tag, or a default icon if the tag is unrecognized.
    private func getSkillIcon(for tag: String) -> String {
        switch tag.lowercased() {
        case "implementation": return "🛠️"
        case "math": return "📐"
        case "greedy": return "💰"
        case "dp": return "🧩"
        case "graph": return "🕸️"
        case "string": return "📝"
        case "sorting": return "📊"
        default: return "⚡"
        }
    }
    
    /// Returns a color from a predefined palette based on the given index, cycling through the palette if the index exceeds its length.
    /// - Parameter index: The index used to select a color.
    /// - Returns: A `Color` corresponding to the index from the palette.
    private func getSkillColor(for index: Int) -> Color {
        let colors: [Color] = [.purple, .blue, .green, .orange, .red]
        return colors[index % colors.count]
    }
}

struct WeaponMasteryChart: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var languageData: [(String, Int)] {
        let languageCounts = Dictionary(grouping: cfService.recentSubmissions) { submission in
            submission.programmingLanguage
        }.mapValues { $0.count }
        
        return Array(languageCounts.sorted { $0.value > $1.value }.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(languageData.enumerated()), id: \.offset) { index, data in
                HStack(spacing: 12) {
                    Text(getWeaponIcon(for: data.0))
                        .font(.system(size: 18))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.0)
                            .font(.custom("TTPhobosTrial-DemiBold", size: 15))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text("\(data.1) battles")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Mastery level
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { level in
                            Circle()
                                .fill(level < getMasteryLevel(count: data.1) ? colorThemeManager.current.accent : colorThemeManager.current.text.opacity(0.2))
                                .frame(width: 7, height: 7)
                        }
                    }
                    
                    Text("\(data.1)")
                        .font(.custom("TTPhobosTrial-Bold", size: 14))
                        .foregroundColor(colorThemeManager.current.accent)
                        .frame(minWidth: 24, alignment: .trailing)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Returns an emoji icon representing the given programming language.
    /// - Parameter language: The name of the programming language.
    /// - Returns: An emoji symbolizing the specified language, or a default icon if not recognized.
    private func getWeaponIcon(for language: String) -> String {
        switch language.lowercased() {
        case let lang where lang.contains("python"): return "🐍"
        case let lang where lang.contains("java"): return "☕"
        case let lang where lang.contains("c++"): return "⚔️"
        case let lang where lang.contains("javascript"): return "🌟"
        case let lang where lang.contains("rust"): return "🦀"
        case let lang where lang.contains("go"): return "🔷"
        default: return "🗡️"
        }
    }
    
    /// Returns the mastery level (1–5) based on the provided count of submissions.
    /// - Parameter count: The number of submissions for a programming language.
    /// - Returns: An integer from 1 to 5 representing the mastery level, with higher levels for greater counts.
    private func getMasteryLevel(count: Int) -> Int {
        switch count {
        case 0...5: return 1
        case 6...15: return 2
        case 16...30: return 3
        case 31...50: return 4
        default: return 5
        }
    }
}

struct BattleResultsChart: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var verdictData: [(String, Int)] {
        let verdictCounts = Dictionary(grouping: cfService.recentSubmissions) { submission in
            submission.verdict ?? "Unknown"
        }.mapValues { $0.count }
        
        return Array(verdictCounts.sorted { $0.value > $1.value })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(verdictData.prefix(5).enumerated()), id: \.offset) { index, data in
                HStack(spacing: 12) {
                    Text(getBattleIcon(for: data.0))
                        .font(.system(size: 18))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(getBattleResult(for: data.0))
                            .font(.custom("TTPhobosTrial-DemiBold", size: 15))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text("\(data.1) battles")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("\(data.1)")
                        .font(.custom("TTPhobosTrial-Bold", size: 14))
                        .foregroundColor(getBattleColor(for: data.0))
                        .frame(minWidth: 32, alignment: .trailing)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorThemeManager.current.background.opacity(0.3))
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Returns an emoji icon representing the given submission verdict.
    /// - Parameter verdict: The verdict string to map to an icon.
    /// - Returns: An emoji corresponding to the verdict type.
    private func getBattleIcon(for verdict: String) -> String {
        switch verdict {
        case "OK", "ACCEPTED": return "🏆"
        case "WRONG_ANSWER": return "❌"
        case "TIME_LIMIT_EXCEEDED": return "⏱️"
        case "RUNTIME_ERROR": return "💥"
        case "COMPILATION_ERROR": return "🔧"
        default: return "⚡"
        }
    }
    
    /// Returns a user-friendly battle result description for a given submission verdict.
    /// - Parameter verdict: The verdict string from a submission.
    /// - Returns: A descriptive label representing the outcome, such as "Victory" or "Defeated". If the verdict is unrecognized, returns the original verdict string.
    private func getBattleResult(for verdict: String) -> String {
        switch verdict {
        case "OK", "ACCEPTED": return "Victory"
        case "WRONG_ANSWER": return "Defeated"
        case "TIME_LIMIT_EXCEEDED": return "Too Slow"
        case "RUNTIME_ERROR": return "Crashed"
        case "COMPILATION_ERROR": return "Weapon Failed"
        default: return verdict
        }
    }
    
    /// Returns a color representing the outcome of a submission based on its verdict.
    /// - Parameter verdict: The verdict string of the submission.
    /// - Returns: A color corresponding to the verdict type (e.g., green for accepted, red for wrong answer).
    private func getBattleColor(for verdict: String) -> Color {
        switch verdict {
        case "OK", "ACCEPTED": return .green
        case "WRONG_ANSWER": return .red
        case "TIME_LIMIT_EXCEEDED": return .orange
        case "RUNTIME_ERROR": return .purple
        case "COMPILATION_ERROR": return .blue
        default: return .gray
        }
    }
}

struct ChallengeLevelChart: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var difficultyData: [(String, Int)] {
        let difficultyCounts = Dictionary(grouping: cfService.recentSubmissions) { submission in
            getDifficultyRange(rating: submission.problem.rating ?? 0)
        }.mapValues { $0.count }
        
        return Array(difficultyCounts.sorted { $0.key < $1.key })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(difficultyData.enumerated()), id: \.offset) { index, data in
                HStack(spacing: 12) {
                    Text(getDifficultyIcon(for: data.0))
                        .font(.system(size: 18))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.0)
                            .font(.custom("TTPhobosTrial-DemiBold", size: 15))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text("\(data.1) attempts")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("\(data.1)")
                        .font(.custom("TTPhobosTrial-Bold", size: 14))
                        .foregroundColor(getDifficultyColor(for: data.0))
                        .frame(minWidth: 24, alignment: .trailing)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Returns the difficulty range label corresponding to a given problem rating.
    /// - Parameter rating: The problem's rating value.
    /// - Returns: A string representing the difficulty category (e.g., "Novice", "Expert") for the specified rating.
    private func getDifficultyRange(rating: Int) -> String {
        switch rating {
        case 0...1199: return "Novice"
        case 1200...1399: return "Apprentice"
        case 1400...1599: return "Warrior"
        case 1600...1899: return "Expert"
        case 1900...2099: return "Master"
        case 2100...2299: return "Grandmaster"
        default: return "Legend"
        }
    }
    
    /// Returns the emoji icon associated with a given difficulty level label.
    /// - Parameter difficulty: The difficulty level as a string (e.g., "Novice", "Expert").
    /// - Returns: An emoji representing the specified difficulty, or a default icon if the label is unrecognized.
    private func getDifficultyIcon(for difficulty: String) -> String {
        switch difficulty {
        case "Novice": return "🌱"
        case "Apprentice": return "🗡️"
        case "Warrior": return "⚔️"
        case "Expert": return "🛡️"
        case "Master": return "👑"
        case "Grandmaster": return "💎"
        case "Legend": return "🌟"
        default: return "⚡"
        }
    }
    
    /// Returns a color associated with the specified difficulty level.
    /// - Parameter difficulty: The difficulty label (e.g., "Novice", "Expert").
    /// - Returns: The corresponding color for the given difficulty, or gray if the label is unrecognized.
    private func getDifficultyColor(for difficulty: String) -> Color {
        switch difficulty {
        case "Novice": return .green
        case "Apprentice": return .blue
        case "Warrior": return .orange
        case "Expert": return .purple
        case "Master": return .red
        case "Grandmaster": return .pink
        case "Legend": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Stats Grid
struct DungeonStatsGrid: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            DungeonStatCard(
                icon: "⚔️",
                title: "Total Battles",
                value: "\(cfService.recentSubmissions.count)",
                subtitle: "all time",
                color: .blue
            )
            
            DungeonStatCard(
                icon: "🏆",
                title: "Victories",
                value: "\(cfService.recentSubmissions.filter { $0.isAccepted }.count)",
                subtitle: "problems solved",
                color: .green
            )
            
            DungeonStatCard(
                icon: "📈",
                title: "Win Rate",
                value: "\(Int(cfService.recentSubmissions.isEmpty ? 0 : Double(cfService.recentSubmissions.filter { $0.isAccepted }.count) / Double(cfService.recentSubmissions.count) * 100))%",
                subtitle: "success rate",
                color: .orange
            )
            
            DungeonStatCard(
                icon: "🔥",
                title: "This Week",
                value: "\(cfService.recentSubmissions.filter { $0.submissionDate > Date().addingTimeInterval(-7*24*60*60) }.count)",
                subtitle: "recent battles",
                color: .purple
            )
        }
    }
}

struct DungeonStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: color.opacity(0.1), radius: 6, y: 2)
        )
    }
}

// MARK: - Placeholder Cards (will be implemented based on existing logic)
struct CurrentObjectivesCard: View {
    let dailySolved: Int
    let weeklySolved: Int
    let currentStreak: Int
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📋 Current Objectives")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
                
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 14))
                        Text("\(currentStreak)")
                            .font(.custom("TTPhobosTrial-Bold", size: 14))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorThemeManager.current.accent.opacity(0.1))
                    )
                }
            }
            
            VStack(spacing: 12) {
                ObjectiveRow(
                    icon: "🎯",
                    title: "Daily Quest",
                    description: "Solve 3 problems today",
                    progress: min(Double(dailySolved) / 3.0, 1.0),
                    currentCount: dailySolved,
                    targetCount: 3
                )
                
                ObjectiveRow(
                    icon: "⚡",
                    title: "Weekly Challenge",
                    description: "Solve 15 problems this week",
                    progress: min(Double(weeklySolved) / 15.0, 1.0),
                    currentCount: weeklySolved,
                    targetCount: 15
                )
                
                ObjectiveRow(
                    icon: "🔥",
                    title: "Maintain Streak",
                    description: "Keep solving daily",
                    progress: currentStreak > 0 ? 1.0 : 0.0,
                    currentCount: currentStreak,
                    targetCount: nil
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

struct ObjectiveRow: View {
    let icon: String
    let title: String
    let description: String
    let progress: Double
    let currentCount: Int
    let targetCount: Int?
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Spacer()
                    
                    if let target = targetCount {
                        Text("\(currentCount)/\(target)")
                            .font(.custom("TTPhobosTrial-Bold", size: 12))
                            .foregroundColor(colorThemeManager.current.accent)
                    } else {
                        Text("\(currentCount) days")
                            .font(.custom("TTPhobosTrial-Bold", size: 12))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
                
                Text(description)
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(colorThemeManager.current.accent)
                    .scaleEffect(y: 0.5)
            }
            
            Spacer()
            
            Text("\(Int(progress * 100))%")
                .font(.custom("TTPhobosTrial-Bold", size: 12))
                .foregroundColor(colorThemeManager.current.accent)
        }
    }
}

struct SkillProgressionCard: View {
    let weakestTopics: [String]
    let difficultyRange: String
    let cfService: CFService
    let geminiService: GeminiService
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var aiSuggestion: String = ""
    @State private var isLoadingSuggestion = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🌟 Skill Progression")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
                
                Button(action: loadAISuggestion) {
                    HStack(spacing: 4) {
                        if isLoadingSuggestion {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(colorThemeManager.current.accent)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                        }
                        Text("AI Insight")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    }
                    .foregroundColor(colorThemeManager.current.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorThemeManager.current.accent.opacity(0.1))
                    )
                }
                .disabled(isLoadingSuggestion)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Weakness Analysis
                if !weakestTopics.isEmpty {
                    SkillMetric(
                        icon: "🎯",
                        title: "Focus Areas",
                        value: weakestTopics.joined(separator: ", "),
                        description: "Topics to improve"
                    )
                }
                
                // Difficulty Range
                SkillMetric(
                    icon: "📊",
                    title: "Recent Range",
                    value: difficultyRange,
                    description: "Problem difficulty spread"
                )
                
                // Total Solved
                let totalSolved = cfService.recentSubmissions.filter { $0.isAccepted }.count
                SkillMetric(
                    icon: "✅",
                    title: "Total Solved",
                    value: "\(totalSolved)",
                    description: "Accepted submissions"
                )
                
                // AI Suggestion
                if !aiSuggestion.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🤖")
                                .font(.system(size: 14))
                            Text("AI Recommendation")
                                .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                                .foregroundColor(colorThemeManager.current.text)
                        }
                        
                        Text(aiSuggestion)
                            .font(.custom("TTPhobosTrial-Regular", size: 13))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.8))
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorThemeManager.current.accent.opacity(0.05))
                            .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
        .onAppear {
            if aiSuggestion.isEmpty {
                loadAISuggestion()
            }
        }
    }
    
    /// Asynchronously loads a personalized practice suggestion using recent accepted submissions and updates the AI suggestion state.
    /// If fetching the suggestion fails, sets a default suggestion based on weakest topics and recent difficulty range.
    private func loadAISuggestion() {
        guard !isLoadingSuggestion else { return }
        
        isLoadingSuggestion = true
        
        Task {
            do {
                // Create a summary of recent submissions for Gemini
                let recentAccepted = cfService.recentSubmissions.filter { $0.isAccepted }.prefix(20)
                let problemsSummary = recentAccepted.map { submission in
                    "Problem: \(submission.problem.name), Rating: \(submission.problem.rating ?? 0), Tags: \(submission.problem.tags.joined(separator: ", "))"
                }.joined(separator: "\n")
                
                let suggestion = try await geminiService.getPersonalizedPracticeSuggestionAsync(problemsSummary: problemsSummary)
                
                await MainActor.run {
                    self.aiSuggestion = suggestion
                    self.isLoadingSuggestion = false
                }
            } catch {
                await MainActor.run {
                    self.aiSuggestion = "Focus on your weak areas: \(weakestTopics.joined(separator: ", ")). Practice problems in the \(difficultyRange) rating range."
                    self.isLoadingSuggestion = false
                }
            }
        }
    }
}

struct CombatHistoryCard: View {
    let cfService: CFService
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var recentBattles: [CFSubmission] {
        cfService.recentSubmissions.prefix(5).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("⚔️ Recent Combat History")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
                
                NavigationLink(destination: SubmissionsView()) {
                    Text("View All")
                        .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        .foregroundColor(colorThemeManager.current.accent)
                }
            }
            
            if recentBattles.isEmpty {
                Text("No recent battles found. Start your coding journey!")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
            } else {
                VStack(spacing: 8) {
                    ForEach(recentBattles, id: \.id) { submission in
                        BattleHistoryRow(submission: submission)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

struct SkillMetric: View {
    let icon: String
    let title: String
    let value: String
    let description: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Spacer()
                    
                    Text(value)
                        .font(.custom("TTPhobosTrial-Bold", size: 13))
                        .foregroundColor(colorThemeManager.current.accent)
                        .lineLimit(1)
                }
                
                Text(description)
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
            }
        }
    }
}

struct BattleHistoryRow: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Text(submission.isAccepted ? "✅" : "❌")
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(submission.problem.name)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 13))
                    .foregroundColor(colorThemeManager.current.text)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let rating = submission.problem.rating {
                        Text("⭐ \(rating)")
                            .font(.custom("TTPhobosTrial-Regular", size: 11))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                    
                    Text(timeAgoString(from: submission.submissionDate))
                        .font(.custom("TTPhobosTrial-Regular", size: 11))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Verdict
            Text(submission.verdict ?? "Unknown")
                .font(.custom("TTPhobosTrial-Bold", size: 10))
                .foregroundColor(submission.isAccepted ? .green : .red)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill((submission.isAccepted ? Color.green : Color.red).opacity(0.1))
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorThemeManager.current.background.opacity(0.3))
        )
    }
    
    /// Returns a human-readable string representing the time elapsed since the given date, formatted as minutes, hours, or days ago.
    /// - Parameter date: The date to compare against the current time.
    /// - Returns: A string such as "5m ago", "2h ago", or "3d ago" indicating the elapsed time.
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

#Preview {
    DungeonPracticeView()
        .environmentObject(ColorThemeManager())
}
