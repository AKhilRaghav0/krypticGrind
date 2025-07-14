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
                CurrentObjectivesCard()
                    .padding(.horizontal, 20)
                
                // Skill Progression
                SkillProgressionCard()
                    .padding(.horizontal, 20)
                
                // Combat History
                CombatHistoryCard()
                    .padding(.horizontal, 20)
                
                Spacer().frame(height: 50)
            }
            .padding(.top, 20)
        }
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchUserSubmissions(handle: handle, count: 200)
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
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📋 Current Objectives")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ObjectiveRow(
                    icon: "🎯",
                    title: "Daily Quest",
                    description: "Solve 3 problems today",
                    progress: 0.67
                )
                
                ObjectiveRow(
                    icon: "⚡",
                    title: "Weekly Challenge",
                    description: "Master a new algorithm",
                    progress: 0.3
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
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(colorThemeManager.current.text)
                
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
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🌟 Skill Progression")
                .font(.custom("TTPhobosTrial-Bold", size: 18))
                .foregroundColor(colorThemeManager.current.text)
            
            Text("Track your mastery across different skill trees")
                .font(.custom("TTPhobosTrial-Regular", size: 14))
                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
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

struct CombatHistoryCard: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
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
            
            Text("Your latest battles and conquests")
                .font(.custom("TTPhobosTrial-Regular", size: 14))
                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
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

#Preview {
    DungeonPracticeView()
        .environmentObject(ColorThemeManager())
}
