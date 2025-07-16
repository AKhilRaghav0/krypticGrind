//
//  SubmissionsView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct SubmissionsView_DISABLED: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var selectedFilter: BattleFilter = .all
    @State private var searchText = ""
    @State private var filteredSubmissions: [CFSubmission] = []
    @State private var isLoading = false
    @State private var currentPage = 0
    @State private var isLoadingMore = false
    @State private var hasMoreData = true
    
    // Performance optimization constants
    private let pageSize = 20
    private let maxCachedItems = 100
    
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
                        LazyVStack(spacing: 16) {
                            // Lightweight Stats
                            if !cfService.recentSubmissions.isEmpty {
                                LightweightStatsRow()
                                    .padding(.horizontal, 20)
                            }
                            
                            // Simple Search and Filter - DISABLED FOR PERFORMANCE
                            // VStack(spacing: 12) {
                            //     LightweightSearchBar(searchText: $searchText)
                            //         .padding(.horizontal, 20)
                            //     
                            //     LightweightFilterTabs(selectedFilter: $selectedFilter)
                            // }
                            
                            // Simple Battle List
                            if isLoading && currentPage == 0 {
                                ProgressView("Loading battles...")
                                    .frame(height: 200)
                            } else if filteredSubmissions.isEmpty && !isLoading {
                                VStack(spacing: 16) {
                                    Text("⚔️")
                                        .font(.system(size: 48))
                                        .opacity(0.5)
                                    Text("No battles found")
                                        .font(.custom("TTPhobosTrial-Regular", size: 16))
                                        .foregroundColor(colorThemeManager.current.textSecondary)
                                }
                                .frame(height: 200)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredSubmissions.prefix(50), id: \.id) { submission in
                                        // LightweightBattleCard(submission: submission) - Disabled for performance
                                        UltraLightweightBattleLogCard(submission: submission)
                                            .padding(.horizontal, 20)
                                    }
                                }
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
                await loadInitialData(handle: handle)
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            resetAndFilter()
        }
        .onChange(of: searchText) { _, _ in
            resetAndFilter()
        }
        .onChange(of: cfService.recentSubmissions) { _, _ in
            resetAndFilter()
        }
    }
    
    // MARK: - Optimized Data Loading Methods
    
    @MainActor
    private func loadInitialData(handle: String) async {
        isLoading = true
        currentPage = 0
        hasMoreData = true
        
        await cfService.fetchUserSubmissions(handle: handle, count: maxCachedItems)
        await filterSubmissions()
        
        isLoading = false
    }
    
    private func resetAndFilter() {
        currentPage = 0
        hasMoreData = true
        Task {
            await filterSubmissions()
        }
    }
    
    private func loadMoreSubmissions() {
        guard !isLoadingMore && hasMoreData else { return }
        
        Task {
            await loadMoreData()
        }
    }
    
    @MainActor
    private func loadMoreData() async {
        isLoadingMore = true
        currentPage += 1
        
        // Simulate pagination - in a real app, this would fetch more data from the API
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, cfService.recentSubmissions.count)
        
        if startIndex >= cfService.recentSubmissions.count {
            hasMoreData = false
        } else {
            await filterSubmissions()
        }
        
        isLoadingMore = false
    }
    
    private var userSubtitle: String {
        if let handle = UserDefaults.standard.savedHandle {
            return "\(handle)'s Combat History"
        }
        return "Combat History"
    }
    
    // Async filtering to prevent UI hangs with pagination
    @MainActor
    private func filterSubmissions() async {
        if currentPage == 0 {
            isLoading = true
        }
        
        let filtered = await Task.detached(priority: .userInitiated) { [cfService, selectedFilter, searchText, currentPage, pageSize] in
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
            
            // Apply search with optimized filtering
            if !searchText.isEmpty {
                let lowercaseSearch = searchText.lowercased()
                submissions = submissions.filter { submission in
                    submission.problem.name.lowercased().contains(lowercaseSearch) ||
                    submission.problem.index.lowercased().contains(lowercaseSearch) ||
                    submission.programmingLanguage.lowercased().contains(lowercaseSearch)
                }
            }
            
            // Apply pagination
            let startIndex = 0
            let endIndex = min((currentPage + 1) * pageSize, submissions.count)
            return Array(submissions[startIndex..<endIndex])
        }.value
        
        if currentPage == 0 {
            filteredSubmissions = filtered
        } else {
            filteredSubmissions.append(contentsOf: filtered.suffix(from: currentPage * pageSize))
        }
        
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
    @Binding var selectedFilter: SubmissionsView_DISABLED.BattleFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SubmissionsView_DISABLED.BattleFilter.allCases, id: \.self) { filter in
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
    let filter: SubmissionsView_DISABLED.BattleFilter
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

// MARK: - Optimized Battle Logs List with Pagination
struct OptimizedBattleLogsList: View {
    let submissions: [CFSubmission]
    let isLoadingMore: Bool
    let hasMoreData: Bool
    let onLoadMore: () -> Void
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(submissions, id: \.id) { submission in
                BattleLogCard(submission: submission)
                    .onAppear {
                        // Load more when near the end
                        if submission.id == submissions.last?.id && hasMoreData && !isLoadingMore {
                            onLoadMore()
                        }
                    }
            }
            
            // Loading indicator at bottom
            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color.blue)
                    Text("Loading more battles...")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Battle Log Card
struct BattleLogCard: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var isExpanded = false
    @State private var pulseScale: Double = 1.0
    
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
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true),
                            value: pulseScale
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
                
                // RPG-style corner accents (instead of shimmer)
                VStack {
                    HStack {
                        // Top-left corner accent
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 20))
                            path.addLine(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 20, y: 0))
                        }
                        .stroke(battleStatusColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        
                        Spacer()
                        
                        // Top-right corner accent
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 20, y: 0))
                            path.addLine(to: CGPoint(x: 20, y: 20))
                        }
                        .stroke(battleStatusColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    }
                    
                    Spacer()
                    
                    HStack {
                        // Bottom-left corner accent
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: 20))
                            path.addLine(to: CGPoint(x: 0, y: 20))
                            path.addLine(to: CGPoint(x: 0, y: 0))
                        }
                        .stroke(battleStatusColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        
                        Spacer()
                        
                        // Bottom-right corner accent
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 20))
                            path.addLine(to: CGPoint(x: 20, y: 20))
                            path.addLine(to: CGPoint(x: 20, y: 0))
                        }
                        .stroke(battleStatusColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    }
                }
                .padding(12)
                
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
            // Trigger subtle pulse animation for status icon
            pulseScale = 1.05
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
    // Removed glowIntensity for performance
    
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
                        )                                    // Simple highlight (no animation for performance)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.verdictColor(for: verdict ?? "").opacity(0.15))
                }
            }
            .onAppear {
                // Remove animated glow for performance
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
                .font(.custom("TTPhobosTrial-Bold", size: 11))
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
    
    var body: some View {
        VStack(spacing: 28) {
            // Static icon with enhanced styling
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
            }
        }
        .padding(40)
    }
    
    private var emptyIcon: String {
        switch filter {
        case .all: return "📜"
        case .victories: return "🏆"
        case .defeats: return "💀"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all: return "No Battle Logs"
        case .victories: return "No Victories Yet"
        case .defeats: return "No Defeats"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all: return "Start solving problems to see your battle history here. Every submission tells a story of your coding journey."
        case .victories: return "Keep fighting! Your victories will appear here. Each solved problem is a step towards mastery."
        case .defeats: return "Great! No defeats found for this filter. Your persistence is paying off."
        }
    }
}

// MARK: - Lightweight Performance Components

struct LightweightStatsRow: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            LightweightStatItem(title: "Victories", value: "\(acceptedCount)", color: .green)
            LightweightStatItem(title: "Total", value: "\(cfService.recentSubmissions.count)", color: .blue)
            LightweightStatItem(title: "Rate", value: "\(winRate)%", color: .orange)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(colorThemeManager.current.surface.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var acceptedCount: Int {
        cfService.recentSubmissions.filter { $0.isAccepted }.count
    }
    
    private var winRate: Int {
        guard cfService.recentSubmissions.count > 0 else { return 0 }
        return Int(Double(acceptedCount) / Double(cfService.recentSubmissions.count) * 100)
    }
}

struct LightweightStatItem: View {
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("TTPhobosTrial-Bold", size: 18))
                .foregroundColor(color)
            
            Text(title)
                .font(.custom("TTPhobosTrial-Regular", size: 12))
                .foregroundColor(colorThemeManager.current.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct UltraLightweightBattleLogCard: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Simple status indicator
            Text(submission.isAccepted ? "✓" : "✗")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(submission.isAccepted ? Color.green : Color.red)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(submission.problem.name)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                    .lineLimit(1)
                
                Text("\(submission.problem.index) • \(submission.programmingLanguage)")
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(colorThemeManager.current.surface.opacity(0.2))
        .cornerRadius(6)
    }
}

// MARK: - Ultra-Lightweight SubmissionsView (MAXIMUM PERFORMANCE)
struct SubmissionsView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var selectedFilter: BattleFilter = .all
    @State private var filteredSubmissions: [CFSubmission] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
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
                        VStack(spacing: 24) {
                            // Battle Stats Overview (matching rating screen pattern)
                            if !cfService.recentSubmissions.isEmpty {
                                BattleStatsOverview()
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                            }
                            
                            // Filter Selector (matching practice screen pattern)
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
        .environmentObject(colorThemeManager)
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
    
    // MARK: - Data Loading
    @MainActor
    private func loadInitialData(handle: String) async {
        isLoading = true
        await cfService.fetchUserSubmissions(handle: handle, count: 50)
        await filterSubmissions()
        isLoading = false
    }
    
    @MainActor
    private func filterSubmissions() async {
        // Process submissions efficiently
        let submissions = Array(cfService.recentSubmissions.prefix(50))
        
        var filtered = submissions
        
        // Apply filter
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

// MARK: - Epic Battle Stats Header
struct EpicBattleStatsHeader: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var battleStats: (victories: Int, defeats: Int, winRate: Int) {
        let victories = cfService.recentSubmissions.filter { $0.isAccepted }.count
        let total = cfService.recentSubmissions.count
        let defeats = total - victories
        let winRate = total > 0 ? Int((Double(victories) / Double(total)) * 100) : 0
        return (victories, defeats, winRate)
    }
    
    var body: some View {
        ZStack {
            // Epic background with multiple layers
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            colorThemeManager.current.accent.opacity(0.08),
                            colorThemeManager.current.surface,
                            colorThemeManager.current.surface.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.accent.opacity(0.3),
                                    colorThemeManager.current.accent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("⚔️")
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Warrior Statistics")
                            .font(.custom("TTPhobosTrial-Bold", size: 18))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text("Your battlefield performance")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("🏰")
                        .font(.system(size: 20))
                }
                
                // Stats Grid
                HStack(spacing: 16) {
                    EpicStatCard(
                        title: "Victories",
                        value: "\(battleStats.victories)",
                        icon: "🏆",
                        color: .green
                    )
                    
                    EpicStatCard(
                        title: "Defeats", 
                        value: "\(battleStats.defeats)",
                        icon: "💀",
                        color: .red
                    )
                    
                    EpicStatCard(
                        title: "Win Rate",
                        value: "\(battleStats.winRate)%",
                        icon: "⚡",
                        color: colorThemeManager.current.accent
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Epic Stat Card
struct EpicStatCard: View {
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
                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - RPG Search Bar  
struct RPGSearchBar: View {
    @Binding var searchText: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colorThemeManager.current.accent)
                
                TextField("Search your battles...", text: $searchText)
                    .font(.custom("TTPhobosTrial-Regular", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorThemeManager.current.surface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Epic Battle Filter Tabs
struct EpicBattleFilterTabs: View {
    @Binding var selectedFilter: SubmissionsView.BattleFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SubmissionsView.BattleFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        HStack(spacing: 8) {
                            Text(filter.icon)
                                .font(.system(size: 16))
                            
                            Text(filter.displayName)
                                .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        }
                        .foregroundColor(selectedFilter == filter ? .white : colorThemeManager.current.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? colorThemeManager.current.accent : colorThemeManager.current.surface.opacity(0.5))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            selectedFilter == filter ? Color.clear : colorThemeManager.current.accent.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Epic Battle Log Card
struct EpicBattleLogCard: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            // Epic background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            colorThemeManager.current.surface.opacity(0.9),
                            colorThemeManager.current.surface.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(battleResultColor.opacity(0.3), lineWidth: 1)
                )
            
            HStack(spacing: 16) {
                // Epic battle result icon
                ZStack {
                    Circle()
                        .fill(battleResultColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(battleResultColor.opacity(0.4), lineWidth: 2)
                        )
                    
                    Text(battleIcon)
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(submission.problem.name)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(colorThemeManager.current.text)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("Problem \(submission.problem.index)")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                        
                        Text("•")
                            .foregroundColor(colorThemeManager.current.text.opacity(0.3))
                        
                        Text(submission.programmingLanguage)
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(battleVerdict)
                        .font(.custom("TTPhobosTrial-Bold", size: 14))
                        .foregroundColor(battleResultColor)
                    
                    Text(submission.submissionDate.timeAgo())
                        .font(.custom("TTPhobosTrial-Regular", size: 10))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                }
            }
            .padding(16)
        }
    }
    
    private var battleIcon: String {
        submission.isAccepted ? "⚔️" : "💀"
    }
    
    private var battleVerdict: String {
        submission.isAccepted ? "VICTORY" : "DEFEAT"
    }
    
    private var battleResultColor: Color {
        submission.isAccepted ? .green : .red
    }
}

// MARK: - Epic Loading View
struct EpicLoadingView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(colorThemeManager.current.accent.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                Text("⚔️")
                    .font(.system(size: 28))
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            
            Text("Loading Battle Chronicles...")
                .font(.custom("TTPhobosTrial-Bold", size: 16))
                .foregroundColor(colorThemeManager.current.text)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Epic Empty Battle View
struct EpicEmptyBattleView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📜")
                .font(.system(size: 48))
                .opacity(0.6)
            
            VStack(spacing: 8) {
                Text("No Battles Found")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text("Your legendary quests will appear here")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Battle Stats Overview (matching rating screen pattern)
struct BattleStatsOverview: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            // Container background matching rating screen
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
                    StatCard(
                        title: "Total Battles",
                        value: "\(cfService.recentSubmissions.count)",
                        icon: "⚔️",
                        color: colorThemeManager.current.accent
                    )
                    
                    StatCard(
                        title: "Victories",
                        value: "\(victoryCount)",
                        icon: "🏆",
                        color: .green
                    )
                    
                    StatCard(
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

// MARK: - Battle Filter Selector (matching practice screen pattern)
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

// MARK: - Filter Tab Component
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

// MARK: - Battle Log Card (cleaner design)
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
                        
                        Text(submission.programmingLanguage)
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