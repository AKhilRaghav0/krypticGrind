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
                    // Simple Centered Title (blends with top)
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 8) // Blend with safe area
                        
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
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with icon and title
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.accent.opacity(0.3),
                                    colorThemeManager.current.accent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            colorThemeManager.current.accent.opacity(0.6),
                                            colorThemeManager.current.accent.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Text("📊")
                        .font(.system(size: 18))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                Text("Battle Statistics")
                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.textPrimary,
                                colorThemeManager.current.textPrimary.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
            
            // Stats grid with premium cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
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
        .padding(24)
        .background {
            ZStack {
                // Base gradient background
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.surface.opacity(0.95),
                                colorThemeManager.current.surface.opacity(0.85),
                                colorThemeManager.current.surface.opacity(0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle overlay gradient
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                colorThemeManager.current.accent.opacity(0.03),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                
                // Border with gradient
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.accent.opacity(0.2),
                                colorThemeManager.current.divider.opacity(0.3),
                                colorThemeManager.current.accent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .shadow(color: colorThemeManager.current.accent.opacity(0.1), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 8)
        .onAppear {
            isAnimating = true
        }
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
    @State private var isHovered = false
    @State private var animationOffset = 0.0
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with enhanced styling
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.2),
                                color.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.4),
                                        color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                Text(icon)
                    .font(.system(size: 20))
                    .offset(y: animationOffset)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: animationOffset
                    )
            }
            
            // Value with gradient text
            Text(value)
                .font(.custom("TTPhobosTrial-Bold", size: 22))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title and subtitle
            VStack(spacing: 4) {
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 13))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 11))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background {
            ZStack {
                // Base card background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.surface.opacity(0.8),
                                colorThemeManager.current.surface.opacity(0.6),
                                colorThemeManager.current.surface.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Color accent overlay
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.08),
                                color.opacity(0.03),
                                color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Animated border
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(isHovered ? 0.5 : 0.3),
                                color.opacity(isHovered ? 0.2 : 0.1),
                                color.opacity(isHovered ? 0.3 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 1.5 : 1
                    )
                    .animation(.easeInOut(duration: 0.3), value: isHovered)
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: color.opacity(0.15), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isHovered.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isHovered = false
                }
            }
        }
        .onAppear {
            animationOffset = -2
        }
    }
}

// MARK: - Battle Search Bar
struct BattleSearchBar: View {
    @Binding var searchText: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.accent.opacity(0.15),
                                colorThemeManager.current.accent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                colorThemeManager.current.accent.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                
                Text("🔍")
                    .font(.system(size: 16))
            }
            
            TextField("Search battles...", text: $searchText)
                .font(.custom("TTPhobosTrial-Regular", size: 16))
                .foregroundColor(colorThemeManager.current.textPrimary)
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    isFocused = true
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isFocused = false
                }) {
                    ZStack {
                        Circle()
                            .fill(colorThemeManager.current.errorColor.opacity(0.1))
                            .frame(width: 24, height: 24)
                        
                        Text("✕")
                            .font(.system(size: 12))
                            .foregroundColor(colorThemeManager.current.errorColor)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.surface.opacity(0.9),
                                colorThemeManager.current.surface.opacity(0.7),
                                colorThemeManager.current.surface.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Focus overlay
                if isFocused {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.accent.opacity(0.03),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Border with animation
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isFocused ? colorThemeManager.current.accent.opacity(0.4) : colorThemeManager.current.divider.opacity(0.6),
                                isFocused ? colorThemeManager.current.accent.opacity(0.2) : colorThemeManager.current.divider.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: isFocused ? 1.5 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            }
        }
        .shadow(color: isFocused ? colorThemeManager.current.accent.opacity(0.1) : .clear, radius: 8, x: 0, y: 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
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
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Enhanced icon with background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    (isSelected ? Color.white.opacity(0.2) : filter.color.opacity(0.1)),
                                    (isSelected ? Color.white.opacity(0.1) : filter.color.opacity(0.05))
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                    
                    Text(filter.systemImage)
                        .font(.system(size: 14))
                }
                
                Text(filter.rawValue)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 15))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                isSelected ? .white : colorThemeManager.current.textPrimary,
                                isSelected ? .white.opacity(0.9) : colorThemeManager.current.textPrimary.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                ZStack {
                    if isSelected {
                        // Selected state background
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        filter.color,
                                        filter.color.opacity(0.8),
                                        filter.color.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Inner glow for selected state
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        // Unselected state background
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        colorThemeManager.current.surface.opacity(0.8),
                                        colorThemeManager.current.surface.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Border for unselected state
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        filter.color.opacity(0.3),
                                        filter.color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isSelected ? filter.color.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    action()
                }
            }
        }
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
    @State private var isExpanded = false
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Battle Header with enhanced styling
            HStack(spacing: 12) {
                // Battle Result Icon with container
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    battleStatusColor.opacity(0.2),
                                    battleStatusColor.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(battleStatusColor.opacity(0.4), lineWidth: 1)
                        )
                    
                    Text(battleResultIcon)
                        .font(.system(size: 22))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(submission.problem.name)
                        .font(.custom("TTPhobosTrial-Bold", size: 17))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.textPrimary,
                                    colorThemeManager.current.textPrimary.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text("Battle #\(submission.problem.index)")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                            .foregroundColor(colorThemeManager.current.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(colorThemeManager.current.accent.opacity(0.1))
                            )
                        
                        if let rating = submission.problem.rating {
                            Text("\(rating)")
                                .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                                .foregroundColor(Color.ratingColor(for: rating))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.ratingColor(for: rating).opacity(0.1))
                                )
                        } else {
                            Text("Unrated")
                                .font(.custom("TTPhobosTrial-Regular", size: 12))
                                .foregroundColor(colorThemeManager.current.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Enhanced Battle Status Badge
                BattleStatusBadge(verdict: submission.verdict)
            }
            
            // Battle Stats with premium styling
            HStack(spacing: 0) {
                BattleStatItem(
                    icon: "⏱️",
                    label: "Time",
                    value: "\(submission.timeConsumedMillis)ms"
                )
                
                Rectangle()
                    .fill(colorThemeManager.current.divider.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                BattleStatItem(
                    icon: "🧠",
                    label: "Memory", 
                    value: "\(submission.memoryConsumedBytes / 1024)KB"
                )
                
                Rectangle()
                    .fill(colorThemeManager.current.divider.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                BattleStatItem(
                    icon: "⚡",
                    label: "Language",
                    value: submission.programmingLanguage
                )
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.surface.opacity(0.3),
                                colorThemeManager.current.surface.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            
            // Battle Timestamp and Actions
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(colorThemeManager.current.textSecondary.opacity(0.1))
                            .frame(width: 20, height: 20)
                        
                        Text("🕐")
                            .font(.system(size: 10))
                    }
                    
                    Text("Fought \(submission.submissionDate.timeAgo())")
                        .font(.custom("TTPhobosTrial-Regular", size: 13))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                }
                
                Spacer()
                
                if let contestId = submission.contestId {
                    Button(action: {
                        if let url = URL(string: "https://codeforces.com/contest/\(contestId)/problem/\(submission.problem.index)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("🔗")
                                .font(.system(size: 12))
                            Text("View Problem")
                                .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                                .foregroundColor(colorThemeManager.current.accent)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(colorThemeManager.current.accent.opacity(0.1))
                                .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(20)
        .background {
            ZStack {
                // Base card background with multiple layers
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.surface.opacity(0.95),
                                colorThemeManager.current.surface.opacity(0.85),
                                colorThemeManager.current.surface.opacity(0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Status color overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                battleStatusColor.opacity(0.06),
                                battleStatusColor.opacity(0.02),
                                battleStatusColor.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Shimmer effect overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                colorThemeManager.current.textPrimary.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .mask(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                
                // Enhanced border
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                battleStatusColor.opacity(0.3),
                                battleStatusColor.opacity(0.1),
                                battleStatusColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        }
        .shadow(color: battleStatusColor.opacity(0.12), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
        .onAppear {
            // Trigger shimmer animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
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
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        Text(verdictDisplayText)
            .font(.custom("TTPhobosTrial-Bold", size: 11))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.verdictColor(for: verdict ?? ""),
                                    Color.verdictColor(for: verdict ?? "").opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Glow effect
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.verdictColor(for: verdict ?? "").opacity(glowIntensity * 0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: glowIntensity
                        )
                }
            }
            .shadow(color: Color.verdictColor(for: verdict ?? "").opacity(0.4), radius: 4, x: 0, y: 2)
            .onAppear {
                glowIntensity = 0.8
            }
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
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.accent.opacity(0.1),
                                colorThemeManager.current.accent.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 24, height: 24)
                
                Text(icon)
                    .font(.system(size: 12))
            }
            
            Text(value)
                .font(.custom("TTPhobosTrial-DemiBold", size: 11))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            colorThemeManager.current.textPrimary,
                            colorThemeManager.current.textPrimary.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(.custom("TTPhobosTrial-Regular", size: 9))
                .foregroundColor(colorThemeManager.current.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// MARK: - Loading and Empty States

struct EmptyBattleLogsView: View {
    let filter: SubmissionsView.BattleFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var animationOffset: CGFloat = 0
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 28) {
            // Animated icon with enhanced styling
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                colorThemeManager.current.textSecondary.opacity(0.1),
                                colorThemeManager.current.textSecondary.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        colorThemeManager.current.textSecondary.opacity(0.2),
                                        colorThemeManager.current.textSecondary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                Text(emptyIcon)
                    .font(.system(size: 56))
                    .opacity(0.7)
                    .offset(y: animationOffset)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: animationOffset
                    )
            }
            
            VStack(spacing: 12) {
                Text(emptyTitle)
                    .font(.custom("TTPhobosTrial-Bold", size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.textPrimary,
                                colorThemeManager.current.textPrimary.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(emptyMessage)
                    .font(.custom("TTPhobosTrial-Regular", size: 15))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            
            // Optional action button for certain states
            if filter == .all {
                Button(action: {
                    // Could trigger navigation to practice or contest
                }) {
                    HStack(spacing: 8) {
                        Text("⚔️")
                            .font(.system(size: 16))
                        
                        Text("Start Battling")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                colorThemeManager.current.accent,
                                colorThemeManager.current.accent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: colorThemeManager.current.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            }
        }
        .padding(40)
        .onAppear {
            animationOffset = -8
            isAnimating = true
        }
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
        case .all: return "Start solving problems to see your battle history here. Every submission tells a story of your coding journey."
        case .victories: return "Keep fighting! Your victories will appear here. Each solved problem is a step towards mastery."
        case .defeats: return "Great! No defeats found for this filter. Your persistence is paying off."
        case .today: return "Haven't fought any battles today. Time to start your coding adventure!"
        }
    }
}
