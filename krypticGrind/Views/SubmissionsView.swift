//
//  SubmissionsView.swift
//  KrypticGrind
//
//  Clean redesigned version matching other screens
//

import SwiftUI

struct SubmissionsView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var selectedFilter: BattleFilter = .all
    @State private var filteredSubmissions: [CFSubmission] = []
    @State private var isLoading = false
    
    enum BattleFilter: String, CaseIterable {
        case all = "All Battles"
        case victories = "Victories"
        case defeats = "Defeats"
        case recent = "Recent"
        
        var icon: String {
            switch self {
            case .all: return "⚔️"
            case .victories: return "🏆"
            case .defeats: return "💀"
            case .recent: return "🕐"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .victories: return .green
            case .defeats: return .red
            case .recent: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Simple Centered Title (matching other screens)
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 8)
                        
                        HStack {
                            Spacer()
                            Text("Battle Logs")
                                .font(.custom("TTPhobosTrial-Bold", size: 20))
                                .foregroundColor(colorThemeManager.current.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .background(colorThemeManager.current.background)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Battle Stats Overview
                            if !cfService.recentSubmissions.isEmpty {
                                BattleStatsOverview()
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                            }
                            
                            // Filter Selector
                            BattleFilterSelector(selectedFilter: $selectedFilter)
                                .padding(.horizontal, 20)
                            
                            // Battle Log List
                            BattleLogSection(
                                submissions: filteredSubmissions,
                                isLoading: isLoading
                            )
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .tint(colorThemeManager.current.accent)
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await loadInitialData(handle: handle)
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            Task { await filterSubmissions() }
        }
        .onChange(of: cfService.recentSubmissions) { _, _ in
            Task { await filterSubmissions() }
        }
    }
    
    @MainActor
    private func loadInitialData(handle: String) async {
        isLoading = true
        await cfService.fetchUserSubmissions(handle: handle, count: 50)
        await filterSubmissions()
        isLoading = false
    }
    
    @MainActor
    private func filterSubmissions() async {
        let submissions = Array(cfService.recentSubmissions.prefix(50))
        
        var filtered = submissions
        
        switch selectedFilter {
        case .all:
            break
        case .victories:
            filtered = filtered.filter { $0.isAccepted }
        case .defeats:
            filtered = filtered.filter { !$0.isAccepted }
        case .recent:
            filtered = Array(filtered.prefix(20))
        }
        
        filteredSubmissions = filtered
    }
}

// MARK: - Battle Stats Overview
struct BattleStatsOverview: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            colorThemeManager.current.surface,
                            colorThemeManager.current.surface.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: colorThemeManager.current.accent.opacity(0.1), radius: 10, x: 0, y: 4)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Text("⚔️")
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Battle Statistics")
                                .font(.custom("TTPhobosTrial-Bold", size: 18))
                                .foregroundColor(colorThemeManager.current.textPrimary)
                            
                            Text("Your battlefield performance")
                                .font(.custom("TTPhobosTrial-Regular", size: 14))
                                .foregroundColor(colorThemeManager.current.textPrimary.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Text("🏰")
                        .font(.system(size: 20))
                }
                
                // Stats Grid
                HStack(spacing: 16) {
                    SubmissionStatCard(
                        title: "Total Battles",
                        value: "\(cfService.recentSubmissions.count)",
                        icon: "⚔️",
                        color: colorThemeManager.current.accent
                    )
                    
                    SubmissionStatCard(
                        title: "Victories",
                        value: "\(victoryCount)",
                        icon: "🏆",
                        color: .green
                    )
                    
                    SubmissionStatCard(
                        title: "Win Rate",
                        value: "\(winRate)%",
                        icon: "📊",
                        color: winRate >= 50 ? .green : .orange
                    )
                }
            }
            .padding(20)
        }
    }
    
    private var victoryCount: Int {
        cfService.recentSubmissions.filter { $0.isAccepted }.count
    }
    
    private var winRate: Int {
        let total = cfService.recentSubmissions.count
        guard total > 0 else { return 0 }
        return Int((Double(victoryCount) / Double(total)) * 100)
    }
}

// MARK: - Submission Stat Card
struct SubmissionStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 20))
            
            Text(value)
                .font(.custom("TTPhobosTrial-Bold", size: 18))
                .foregroundColor(color)
            
            Text(title)
                .font(.custom("TTPhobosTrial-Regular", size: 12))
                .foregroundColor(colorThemeManager.current.textPrimary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Battle Filter Selector
struct BattleFilterSelector: View {
    @Binding var selectedFilter: SubmissionsView.BattleFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SubmissionsView.BattleFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Filter Tab
struct FilterTab: View {
    let filter: SubmissionsView.BattleFilter
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(filter.icon)
                    .font(.system(size: 16))
                
                Text(filter.rawValue)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
            }
            .foregroundColor(isSelected ? .white : colorThemeManager.current.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isSelected
                        ? colorThemeManager.current.accent
                        : colorThemeManager.current.surface.opacity(0.6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isSelected
                                ? colorThemeManager.current.accent.opacity(0.3)
                                : colorThemeManager.current.textPrimary.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(
            color: isSelected ? colorThemeManager.current.accent.opacity(0.3) : .clear,
            radius: 6,
            x: 0,
            y: 3
        )
    }
}

// MARK: - Battle Log Section
struct BattleLogSection: View {
    let submissions: [CFSubmission]
    let isLoading: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                LoadingBattleView()
                    .frame(height: 200)
            } else if submissions.isEmpty {
                EmptyBattleView()
                    .frame(height: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(submissions.prefix(20), id: \.id) { submission in
                        BattleLogCard(submission: submission)
                    }
                    
                    if submissions.count > 20 {
                        Text("+ \(submissions.count - 20) more battles")
                            .font(.custom("TTPhobosTrial-Regular", size: 14))
                            .foregroundColor(colorThemeManager.current.accent)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
    }
}

// MARK: - Battle Log Card
struct BattleLogCard: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                // Result indicator
                ZStack {
                    Circle()
                        .fill(resultColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(resultIcon)
                        .font(.system(size: 20))
                }
                
                // Problem info
                VStack(alignment: .leading, spacing: 4) {
                    Text(submission.problem.name)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(colorThemeManager.current.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("Problem \(submission.problem.index)")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.textSecondary)
                        
                        Text("•")
                            .foregroundColor(colorThemeManager.current.textSecondary.opacity(0.5))
                        
                        Text(submission.programmingLanguage)
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
                
                Spacer()
                
                // Result and time
                VStack(alignment: .trailing, spacing: 4) {
                    Text(resultText)
                        .font(.custom("TTPhobosTrial-Bold", size: 12))
                        .foregroundColor(resultColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(resultColor.opacity(0.1))
                        )
                    
                    Text(submission.submissionDate.timeAgo())
                        .font(.custom("TTPhobosTrial-Regular", size: 10))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(resultColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var resultIcon: String {
        submission.isAccepted ? "✓" : "✗"
    }
    
    private var resultText: String {
        submission.isAccepted ? "ACCEPTED" : "FAILED"
    }
    
    private var resultColor: Color {
        submission.isAccepted ? .green : .red
    }
}

// MARK: - Loading and Empty States
struct LoadingBattleView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(colorThemeManager.current.accent)
            
            Text("Loading battles...")
                .font(.custom("TTPhobosTrial-Regular", size: 16))
                .foregroundColor(colorThemeManager.current.textSecondary)
        }
    }
}

struct EmptyBattleView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("⚔️")
                .font(.system(size: 48))
                .opacity(0.5)
            
            VStack(spacing: 8) {
                Text("No battles found")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Text("Start solving problems to see your battle history")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    SubmissionsView()
        .environmentObject(ColorThemeManager())
}
