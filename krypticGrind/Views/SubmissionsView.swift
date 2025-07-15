//
//  SubmissionsView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct SubmissionsView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var selectedFilter: BattleFilter = .all
    @State private var searchText = ""
    @State private var filteredSubmissions: [CFSubmission] = []
    @State private var isLoading = false
    
    enum BattleFilter: String, CaseIterable {
        case all = "All Battles"
        case victories = "Victories"
        case defeats = "Defeats"
        case today = "Today's Battles"
        
        var systemImage: String {
            switch self {
            case .all: return "⚔️"
            case .victories: return "🏆"
            case .defeats: return "💀"
            case .today: return "🌅"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .victories: return .green
            case .defeats: return .red
            case .today: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Dungeon Title Bar
                    DungeonTitleBar(
                        title: "Battle Logs",
                        subtitle: userSubtitle
                    )
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Battle Statistics Dashboard
                            if !cfService.recentSubmissions.isEmpty {
                                BattleStatsDashboard(submissions: cfService.recentSubmissions)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                            }
                            
                            // Search and Filter Section
                            VStack(spacing: 16) {
                                BattleSearchBar(searchText: $searchText)
                                    .padding(.horizontal, 20)
                                
                                BattleFilterTabs(selectedFilter: $selectedFilter)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Battle Logs List
                            if isLoading {
                                BattleLoadingView()
                                    .frame(height: 200)
                            } else if filteredSubmissions.isEmpty {
                                EmptyBattleLogsView(filter: selectedFilter)
                                    .frame(height: 300)
                            } else {
                                BattleLogsList(submissions: filteredSubmissions)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .tint(colorThemeManager.current.accent)
        .environmentObject(colorThemeManager)
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchUserSubmissions(handle: handle, count: 100)
                await filterSubmissions()
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            Task {
                await filterSubmissions()
            }
        }
        .onChange(of: searchText) { _, _ in
            Task {
                await filterSubmissions()
            }
        }
        .onChange(of: cfService.recentSubmissions) { _, _ in
            Task {
                await filterSubmissions()
            }
        }
    }
    
    private var userSubtitle: String {
        if let handle = UserDefaults.standard.savedHandle {
            return "\(handle)'s Combat History"
        }
        return "Combat History"
    }
    
    // Async filtering to prevent UI hangs
    @MainActor
    private func filterSubmissions() async {
        isLoading = true
        
        let filtered = await Task.detached(priority: .userInitiated) { [cfService, selectedFilter, searchText] in
            var submissions = cfService.recentSubmissions
            
            // Apply filter
            switch selectedFilter {
            case .all:
                break
            case .victories:
                submissions = submissions.filter { $0.isAccepted }
            case .defeats:
                submissions = submissions.filter { $0.verdict == "WRONG_ANSWER" }
            case .today:
                submissions = submissions.todaysSubmissions()
            }
            
            // Apply search
            if !searchText.isEmpty {
                submissions = submissions.filter { submission in
                    submission.problem.name.localizedCaseInsensitiveContains(searchText) ||
                    submission.problem.index.localizedCaseInsensitiveContains(searchText) ||
                    submission.programmingLanguage.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            return submissions
        }.value
        
        filteredSubmissions = filtered
        isLoading = false
    }
}

// MARK: - Dungeon Title Bar
struct DungeonTitleBar: View {
    let title: String
    let subtitle: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("⚔️")
                    .font(.system(size: 24))
                
                Text(title)
                    .font(.custom("TTPhobosTrial-Bold", size: 24))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Spacer()
                
                Text("🏰")
                    .font(.system(size: 20))
            }
            
            if !subtitle.isEmpty {
                HStack {
                    Text(subtitle)
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(colorThemeManager.current.surface)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }
}

// MARK: - Battle Statistics Dashboard
struct BattleStatsDashboard: View {
    let submissions: [CFSubmission]
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📊 Battle Statistics")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                BattleStatCard(
                    icon: "🏆",
                    title: "Victories",
                    value: "\(acceptedCount)",
                    subtitle: "Problems solved",
                    color: colorThemeManager.current.successColor
                )
                
                BattleStatCard(
                    icon: "⚔️",
                    title: "Battles",
                    value: "\(submissions.count)",
                    subtitle: "Total attempts",
                    color: colorThemeManager.current.accent
                )
                
                BattleStatCard(
                    icon: "📈",
                    title: "Win Rate",
                    value: "\(winRate)%",
                    subtitle: "Success ratio",
                    color: colorThemeManager.current.warning
                )
                
                BattleStatCard(
                    icon: "🔥",
                    title: "Streak",
                    value: "\(currentStreak)",
                    subtitle: "Current run",
                    color: colorThemeManager.current.highlight
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.9))
                .stroke(colorThemeManager.current.divider, lineWidth: 1)
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
    
    private var acceptedCount: Int {
        submissions.filter { $0.isAccepted }.count
    }
    
    private var winRate: Int {
        guard submissions.count > 0 else { return 0 }
        return Int(Double(acceptedCount) / Double(submissions.count) * 100)
    }
    
    private var currentStreak: Int {
        submissions.calculateStreak()
    }
}

// MARK: - Battle Stat Card
struct BattleStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(value)
                .font(.custom("TTPhobosTrial-Bold", size: 20))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 10))
                    .foregroundColor(colorThemeManager.current.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Battle Search Bar
struct BattleSearchBar: View {
    @Binding var searchText: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text("🔍")
                .font(.system(size: 16))
            
            TextField("Search battles...", text: $searchText)
                .font(.custom("TTPhobosTrial-Regular", size: 16))
                .foregroundColor(colorThemeManager.current.textPrimary)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Text("❌")
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorThemeManager.current.surface)
                .stroke(colorThemeManager.current.divider, lineWidth: 1)
        )
    }
}

// MARK: - Battle Filter Tabs
struct BattleFilterTabs: View {
    @Binding var selectedFilter: SubmissionsView.BattleFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SubmissionsView.BattleFilter.allCases, id: \.self) { filter in
                    BattleFilterTab(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct BattleFilterTab: View {
    let filter: SubmissionsView.BattleFilter
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(filter.systemImage)
                    .font(.system(size: 16))
                
                Text(filter.rawValue)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(isSelected ? .white : colorThemeManager.current.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? filter.color : colorThemeManager.current.surface)
                    .stroke(filter.color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Battle Logs List
struct BattleLogsList: View {
    let submissions: [CFSubmission]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(submissions, id: \.id) { submission in
                BattleLogCard(submission: submission)
            }
        }
    }
}

// MARK: - Battle Log Card
struct BattleLogCard: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Battle Header
            HStack {
                // Battle Result Icon
                Text(battleResultIcon)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(submission.problem.name)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(colorThemeManager.current.textPrimary)
                        .lineLimit(2)
                    
                    Text("Battle #\(submission.problem.index) • \(submission.problem.rating?.description ?? "Unrated")")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                }
                
                Spacer()
                
                // Battle Status Badge
                BattleStatusBadge(verdict: submission.verdict)
            }
            
            // Battle Stats
            HStack(spacing: 16) {
                BattleStatItem(
                    icon: "⏱️",
                    label: "Time",
                    value: "\(submission.timeConsumedMillis)ms"
                )
                
                BattleStatItem(
                    icon: "🧠",
                    label: "Memory", 
                    value: "\(submission.memoryConsumedBytes / 1024)KB"
                )
                
                BattleStatItem(
                    icon: "⚡",
                    label: "Language",
                    value: submission.programmingLanguage
                )
            }
            
            // Battle Timestamp
            HStack {
                Text("🕐")
                    .font(.system(size: 12))
                
                Text("Fought \(submission.submissionDate.timeAgo())")
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                
                Spacer()
                
                if let contestId = submission.contestId {
                    Button(action: {
                        if let url = URL(string: "https://codeforces.com/contest/\(contestId)/problem/\(submission.problem.index)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("🔗")
                                .font(.system(size: 12))
                            Text("View Problem")
                                .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                                .foregroundColor(colorThemeManager.current.accent)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.8))
                .stroke(battleStatusColor, lineWidth: 1)
                .shadow(color: battleStatusColor.opacity(0.2), radius: 4, y: 2)
        )
    }
    
    private var battleResultIcon: String {
        switch submission.verdict {
        case "OK": return "🏆"
        case "WRONG_ANSWER": return "⚔️"
        case "TIME_LIMIT_EXCEEDED": return "⏰"
        case "MEMORY_LIMIT_EXCEEDED": return "🧠"
        case "RUNTIME_ERROR": return "💥"
        case "COMPILATION_ERROR": return "🔧"
        default: return "❓"
        }
    }
    
    private var battleStatusColor: Color {
        Color.verdictColor(for: submission.verdict ?? "")
    }
}

// MARK: - Battle Status Badge
struct BattleStatusBadge: View {
    let verdict: String?
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Text(verdictDisplayText)
            .font(.custom("TTPhobosTrial-Bold", size: 10))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.verdictColor(for: verdict ?? ""))
            )
    }
    
    private var verdictDisplayText: String {
        switch verdict {
        case "OK": return "VICTORY"
        case "WRONG_ANSWER": return "DEFEAT"
        case "TIME_LIMIT_EXCEEDED": return "TIMEOUT"
        case "MEMORY_LIMIT_EXCEEDED": return "OOM"
        case "RUNTIME_ERROR": return "CRASH"
        case "COMPILATION_ERROR": return "COMPILE"
        default: return verdict ?? "UNKNOWN"
        }
    }
}

// MARK: - Battle Stat Item
struct BattleStatItem: View {
    let icon: String
    let label: String
    let value: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 12))
            
            Text(value)
                .font(.custom("TTPhobosTrial-DemiBold", size: 10))
                .foregroundColor(colorThemeManager.current.textPrimary)
            
            Text(label)
                .font(.custom("TTPhobosTrial-Regular", size: 8))
                .foregroundColor(colorThemeManager.current.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading and Empty States

struct EmptyBattleLogsView: View {
    let filter: SubmissionsView.BattleFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text(emptyIcon)
                .font(.system(size: 64))
                .opacity(0.6)
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Text(emptyMessage)
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
    
    private var emptyIcon: String {
        switch filter {
        case .all: return "📜"
        case .victories: return "🏆"
        case .defeats: return "💀"
        case .today: return "🌅"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all: return "No Battle Logs"
        case .victories: return "No Victories Yet"
        case .defeats: return "No Defeats"
        case .today: return "No Battles Today"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all: return "Start solving problems to see your battle history here."
        case .victories: return "Keep fighting! Your victories will appear here."
        case .defeats: return "Great! No defeats found for this filter."
        case .today: return "Haven't fought any battles today. Time to start!"
        }
    }
}

// ...existing code...
