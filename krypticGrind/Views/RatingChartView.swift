//
//  RatingChartView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI
import Charts

struct RatingChartView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var userSubtitle: String {
        if let handle = UserDefaults.standard.savedHandle {
            return "\(handle)'s Power Chronicle"
        }
        return "Rating Journey"
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
                            Text("Power Level")
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
                            // Power Level Header (if user exists)
                            if let user = cfService.currentUser {
                                PowerLevelHeader(user: user)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                            }
                            
                            // Power Level Chart
                            if !cfService.ratingHistory.isEmpty {
                                PowerLevelChart()
                                    .padding(.horizontal, 20)
                            }
                            
                            // Achievement System
                            if let user = cfService.currentUser {
                                PowerLevelAchievements(user: user, submissions: cfService.recentSubmissions)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Rating History List
                            RatingHistorySection()
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
                await cfService.fetchRatingHistory(handle: handle)
            }
        }
    }
}

// MARK: - Power Level Header
struct PowerLevelHeader: View {
    let user: CFUser
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            // Epic background with multiple layers
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.ratingColor(for: user.rating).opacity(0.08),
                            colorThemeManager.current.surface,
                            colorThemeManager.current.surface.opacity(0.95),
                            Color.ratingColor(for: user.rating).opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Animated border glow
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.ratingColor(for: user.rating).opacity(0.6),
                                    colorThemeManager.current.accent.opacity(0.4),
                                    Color.ratingColor(for: user.rating).opacity(0.8),
                                    colorThemeManager.current.accent.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.ratingColor(for: user.rating).opacity(0.2), radius: 12, y: 6)
            
            VStack(spacing: 20) {
                // Power Level Display - Epic RPG Style
                VStack(spacing: 16) {
                    // Title with mystical styling
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(Color.ratingColor(for: user.rating))
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Current Power Level")
                            .font(.custom("TTPhobosTrial-Bold", size: 16))
                            .foregroundColor(colorThemeManager.current.textPrimary)
                        
                        Image(systemName: "bolt.fill")
                            .foregroundColor(Color.ratingColor(for: user.rating))
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    HStack(spacing: 20) {
                        // Rating Display with epic styling
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack {
                                // Glow effect behind rating
                                Text("\(user.rating)")
                                    .font(.custom("TTPhobosTrial-Bold", size: 48))
                                    .foregroundColor(Color.ratingColor(for: user.rating))
                                    .blur(radius: 8)
                                    .opacity(0.3)
                                
                                Text("\(user.rating)")
                                    .font(.custom("TTPhobosTrial-Bold", size: 48))
                                    .foregroundColor(Color.ratingColor(for: user.rating))
                            }
                            
                            Text("Power Points")
                                .font(.custom("TTPhobosTrial-Regular", size: 12))
                                .foregroundColor(colorThemeManager.current.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Epic Rank Badge with premium styling
                        VStack(spacing: 8) {
                            ZStack {
                                // Background glow
                                Circle()
                                    .fill(Color.ratingColor(for: user.rating).opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .blur(radius: 12)
                                
                                // Main badge
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.ratingColor(for: user.rating).opacity(0.9),
                                                Color.ratingColor(for: user.rating),
                                                Color.ratingColor(for: user.rating).opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.3), Color.clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                
                                Text(rankIcon)
                                    .font(.system(size: 24))
                                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                            }
                            
                            Text(rankTitle)
                                .font(.custom("TTPhobosTrial-Bold", size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.ratingColor(for: user.rating))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.ratingColor(for: user.rating).opacity(0.4), radius: 4, y: 2)
                        }
                    }
                    
                    // Enhanced Power Level Progress
                    PowerLevelProgressBar(currentRating: user.rating)
                }
                
                // Achievement Badges Row with premium styling
                if !achievedRanks.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(colorThemeManager.current.accent)
                                .font(.system(size: 14))
                            
                            Text("Achievements Unlocked")
                                .font(.custom("TTPhobosTrial-Bold", size: 14))
                                .foregroundColor(colorThemeManager.current.textPrimary)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(achievedRanks, id: \.self) { rank in
                                ZStack {
                                    // Glow effect
                                    Circle()
                                        .fill(colorThemeManager.current.accent.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .blur(radius: 6)
                                    
                                    // Main badge
                                    Circle()
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
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(colorThemeManager.current.accent.opacity(0.6), lineWidth: 2)
                                        )
                                    
                                    Text(rank)
                                        .font(.system(size: 16))
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    private var rankTitle: String {
        switch user.rating {
        case 0..<1200: return "Novice"
        case 1200..<1400: return "Pupil"
        case 1400..<1600: return "Specialist"
        case 1600..<1900: return "Expert"
        case 1900..<2100: return "Candidate Master"
        case 2100..<2300: return "Master"
        case 2300..<2400: return "International Master"
        case 2400...: return "Grandmaster"
        default: return "Unranked"
        }
    }
    
    private var rankIcon: String {
        switch user.rating {
        case 0..<1200: return "🗡️"
        case 1200..<1400: return "🛡️"
        case 1400..<1600: return "⚔️"
        case 1600..<1900: return "🏹"
        case 1900..<2100: return "👑"
        case 2100..<2300: return "🏆"
        case 2300..<2400: return "🔱"
        case 2400...: return "⚡"
        default: return "🎯"
        }
    }
    
    private var achievedRanks: [String] {
        let rating = user.rating
        var ranks: [String] = []
        
        if rating >= 1200 { ranks.append("🎯") }
        if rating >= 1400 { ranks.append("⭐") }
        if rating >= 1600 { ranks.append("💎") }
        if rating >= 1900 { ranks.append("👑") }
        if rating >= 2100 { ranks.append("🏆") }
        if rating >= 2300 { ranks.append("🔱") }
        if rating >= 2400 { ranks.append("⚡") }
        
        return ranks
    }
}

// MARK: - Power Level Progress Bar
struct PowerLevelProgressBar: View {
    let currentRating: Int
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Next Rank: \(nextRankTitle)")
                    .font(.custom("TTPhobosTrial-Bold", size: 12))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Spacer()
                
                Text("\(currentRating) / \(nextRankThreshold)")
                    .font(.custom("TTPhobosTrial-Bold", size: 12))
                    .foregroundColor(Color.ratingColor(for: currentRating))
            }
            
            // Epic progress bar with multiple layers
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(colorThemeManager.current.surface.opacity(0.3))
                    .frame(height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(colorThemeManager.current.divider.opacity(0.3), lineWidth: 1)
                    )
                
                // Progress fill with gradient and glow
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.ratingColor(for: currentRating).opacity(0.8),
                                Color.ratingColor(for: currentRating),
                                Color.ratingColor(for: currentRating).opacity(0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(16, CGFloat(progressToNextRank) * 280), height: 16)
                    .overlay(
                        // Shine effect
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear,
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: Color.ratingColor(for: currentRating).opacity(0.4), radius: 4, y: 2)
                    .animation(.easeInOut(duration: 0.8), value: progressToNextRank)
            }
            .frame(maxWidth: 280)
        }
    }
    
    private var nextRankThreshold: Int {
        if currentRating < 1200 { return 1200 }
        if currentRating < 1400 { return 1400 }
        if currentRating < 1600 { return 1600 }
        if currentRating < 1900 { return 1900 }
        if currentRating < 2100 { return 2100 }
        if currentRating < 2300 { return 2300 }
        if currentRating < 2400 { return 2400 }
        return currentRating + 100
    }
    
    private var nextRankTitle: String {
        if currentRating < 1200 { return "Pupil" }
        if currentRating < 1400 { return "Specialist" }
        if currentRating < 1600 { return "Expert" }
        if currentRating < 1900 { return "Candidate Master" }
        if currentRating < 2100 { return "Master" }
        if currentRating < 2300 { return "International Master" }
        if currentRating < 2400 { return "Grandmaster" }
        return "Legend"
    }
    
    private var progressToNextRank: Double {
        let previousThreshold = {
            if currentRating < 1200 { return 0 }
            if currentRating < 1400 { return 1200 }
            if currentRating < 1600 { return 1400 }
            if currentRating < 1900 { return 1600 }
            if currentRating < 2100 { return 1900 }
            if currentRating < 2300 { return 2100 }
            if currentRating < 2400 { return 2300 }
            return 2400
        }()
        
        let progress = Double(currentRating - previousThreshold) / Double(nextRankThreshold - previousThreshold)
        return max(0, min(1, progress))
    }
}

// MARK: - Rank Badge
struct RankBadge: View {
    let rank: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Text(rank)
            .font(.system(size: 20))
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(colorThemeManager.current.surface)
                    .stroke(colorThemeManager.current.accent, lineWidth: 2)
            )
    }
}

// MARK: - Power Level Chart
struct PowerLevelChart: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var selectedRating: CFRatingChange?
    
    var body: some View {
        ZStack {
            // Epic container background
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            colorThemeManager.current.surface,
                            colorThemeManager.current.surface.opacity(0.8),
                            colorThemeManager.current.surface.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.accent.opacity(0.3),
                                    colorThemeManager.current.divider.opacity(0.5),
                                    colorThemeManager.current.accent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            
            VStack(spacing: 20) {
                // Epic header with premium styling
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(colorThemeManager.current.accent)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("Battle Power Chronicle")
                                .font(.custom("TTPhobosTrial-Bold", size: 18))
                                .foregroundColor(colorThemeManager.current.textPrimary)
                        }
                        
                        Spacer()
                        
                        if !cfService.ratingHistory.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "swords")
                                    .foregroundColor(colorThemeManager.current.textSecondary)
                                    .font(.system(size: 12))
                                
                                Text("\(cfService.ratingHistory.count) battles")
                                    .font(.custom("TTPhobosTrial-Bold", size: 12))
                                    .foregroundColor(colorThemeManager.current.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(colorThemeManager.current.accent.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // Decorative divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.accent.opacity(0.4),
                                    colorThemeManager.current.accent.opacity(0.8),
                                    colorThemeManager.current.accent.opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .padding(.horizontal, 40)
                }

                // Enhanced Chart
                ZStack {
                    if !cfService.ratingHistory.isEmpty {
                        chartView
                            .frame(height: 320)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                    AxisGridLine()
                                        .foregroundStyle(colorThemeManager.current.divider.opacity(0.2))
                                    AxisTick()
                                        .foregroundStyle(colorThemeManager.current.textSecondary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                                    AxisGridLine()
                                        .foregroundStyle(colorThemeManager.current.divider.opacity(0.2))
                                    AxisTick()
                                        .foregroundStyle(colorThemeManager.current.textSecondary)
                                    AxisValueLabel {
                                        if let rating = value.as(Int.self) {
                                            Text("\(rating)")
                                                .font(.custom("TTPhobosTrial-Regular", size: 10))
                                                .foregroundColor(colorThemeManager.current.textSecondary)
                                        }
                                    }
                                }
                            }
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture { location in
                                            if let contestId = findNearestContest(at: location, geometry: geometry, proxy: chartProxy) {
                                                selectedRating = cfService.ratingHistory.first { $0.contestId == contestId }
                                            }
                                        }
                                }
                            }
                    } else {
                        EmptyPowerLevelChart()
                            .frame(height: 280)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.background.opacity(0.3),
                                    colorThemeManager.current.background.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(colorThemeManager.current.divider.opacity(0.2), lineWidth: 1)
                        )
                )

                // Selected Battle Details
                if let selectedRating = selectedRating {
                    PowerLevelBattleDetails(ratingChange: selectedRating)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Chart Components
    private var chartView: some View {
        Chart(cfService.ratingHistory, id: \.contestId) { ratingChange in
            LineMark(
                x: .value("Contest", ratingChange.ratingUpdateTimeSeconds),
                y: .value("Rating", ratingChange.newRating)
            )
            .foregroundStyle(Color.ratingColor(for: ratingChange.newRating))
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.cardinal)
            
            AreaMark(
                x: .value("Contest", ratingChange.ratingUpdateTimeSeconds),
                y: .value("Rating", ratingChange.newRating)
            )
            .foregroundStyle(areaGradient(for: ratingChange.newRating))
            .interpolationMethod(.cardinal)
            
            // Add point markers for better visibility
            PointMark(
                x: .value("Contest", ratingChange.ratingUpdateTimeSeconds),
                y: .value("Rating", ratingChange.newRating)
            )
            .foregroundStyle(Color.ratingColor(for: ratingChange.newRating))
            .symbolSize(25)
            
            if let selectedRating = selectedRating,
               selectedRating.contestId == ratingChange.contestId {
                RuleMark(x: .value("Contest", ratingChange.ratingUpdateTimeSeconds))
                    .foregroundStyle(colorThemeManager.current.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            }
        }
        .chartXScale(domain: chartXDomain)
        .chartYScale(domain: chartYDomain)
    }
    
    private var chartXDomain: ClosedRange<Double> {
        guard !cfService.ratingHistory.isEmpty else { return 0...1 }
        let timestamps = cfService.ratingHistory.map { Double($0.ratingUpdateTimeSeconds) }
        let minTime = timestamps.min() ?? 0
        let maxTime = timestamps.max() ?? 0
        let padding = (maxTime - minTime) * 0.05 // 5% padding on each side
        return (minTime - padding)...(maxTime + padding)
    }
    
    private var chartYDomain: ClosedRange<Double> {
        guard !cfService.ratingHistory.isEmpty else { return 0...1200 }
        let ratings = cfService.ratingHistory.map { Double($0.newRating) }
        let minRating = ratings.min() ?? 0
        let maxRating = ratings.max() ?? 1200
        let padding = (maxRating - minRating) * 0.1 // 10% padding
        let paddedMin = max(0, minRating - padding)
        let paddedMax = maxRating + padding
        return paddedMin...paddedMax
    }
    
    private func areaGradient(for rating: Int) -> LinearGradient {
        return LinearGradient(
            colors: [
                Color.ratingColor(for: rating).opacity(0.3),
                Color.ratingColor(for: rating).opacity(0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func findNearestContest(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) -> Int? {
        // Simplified nearest contest finding logic
        guard !cfService.ratingHistory.isEmpty else { return nil }
        
        let relativeX = location.x / geometry.size.width
        let index = Int(relativeX * Double(cfService.ratingHistory.count))
        let clampedIndex = max(0, min(cfService.ratingHistory.count - 1, index))
        
        return cfService.ratingHistory[clampedIndex].contestId
    }
}

struct EmptyPowerLevelChart: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("⚔️")
                .font(.system(size: 64))
                .opacity(0.6)
            
            VStack(spacing: 8) {
                Text("No Battle Data Yet")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Text("Your power level journey will appear here once you participate in rated contests")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Call to action
            VStack(spacing: 4) {
                Text("Ready to start your journey?")
                    .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    .foregroundColor(colorThemeManager.current.accent)
                
                Text("🏆 Join your first contest")
                    .font(.custom("TTPhobosTrial-Regular", size: 11))
                    .foregroundColor(colorThemeManager.current.textSecondary)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Power Level Battle Details
struct PowerLevelBattleDetails: View {
    let ratingChange: CFRatingChange
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("⚔️ Battle Details")
                    .font(.custom("TTPhobosTrial-Bold", size: 14))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contest \(ratingChange.contestId)")
                        .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                        .foregroundColor(colorThemeManager.current.textPrimary)
                    
                    Text("Rank: \(ratingChange.rank)")
                        .font(.custom("TTPhobosTrial-Regular", size: 10))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(ratingChange.oldRating)")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                            .foregroundColor(Color.ratingColor(for: ratingChange.oldRating))
                        
                        Text("→")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.textSecondary)
                        
                        Text("\(ratingChange.newRating)")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                            .foregroundColor(Color.ratingColor(for: ratingChange.newRating))
                    }
                    
                    HStack(spacing: 4) {
                        Text(ratingChange.newRating > ratingChange.oldRating ? "+" : "")
                        Text("\(ratingChange.newRating - ratingChange.oldRating)")
                    }
                    .font(.custom("TTPhobosTrial-Bold", size: 10))
                    .foregroundColor(ratingChange.newRating > ratingChange.oldRating ? colorThemeManager.current.successColor : colorThemeManager.current.errorColor)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorThemeManager.current.surface)
                .stroke(colorThemeManager.current.divider, lineWidth: 1)
        )
    }
}

// MARK: - Power Level Achievements
struct PowerLevelAchievements: View {
    let user: CFUser
    let submissions: [CFSubmission]
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            // Epic achievements container
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            colorThemeManager.current.surface,
                            colorThemeManager.current.surface.opacity(0.9),
                            colorThemeManager.current.surface.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.successColor.opacity(0.3),
                                    colorThemeManager.current.accent.opacity(0.4),
                                    colorThemeManager.current.successColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: colorThemeManager.current.successColor.opacity(0.1), radius: 12, y: 6)
            
            VStack(spacing: 20) {
                // Epic header
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(colorThemeManager.current.successColor)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("Battle Achievements")
                                .font(.custom("TTPhobosTrial-Bold", size: 18))
                                .foregroundColor(colorThemeManager.current.textPrimary)
                            
                            Image(systemName: "sparkles")
                                .foregroundColor(colorThemeManager.current.accent)
                                .font(.system(size: 14))
                        }
                        
                        Spacer()
                    }
                    
                    // Decorative divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorThemeManager.current.successColor.opacity(0.4),
                                    colorThemeManager.current.successColor.opacity(0.8),
                                    colorThemeManager.current.successColor.opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .padding(.horizontal, 40)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(achievements, id: \.id) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
            }
            .padding(24)
        }
    }
    
    private var achievements: [Achievement] {
        var result: [Achievement] = []
        
        // Rating-based achievements
        let rating = user.rating
        if rating >= 1200 {
                result.append(Achievement(
                    id: "pupil",
                    icon: "🎯",
                    title: "First Steps",
                    description: "Reached Pupil rank",
                    isUnlocked: true
                ))
            }
            
            if rating >= 1600 {
                result.append(Achievement(
                    id: "expert",
                    icon: "💎", 
                    title: "Expert Warrior",
                    description: "Reached Expert rank",
                    isUnlocked: true
                ))
            }
            
            if rating >= 2100 {
                result.append(Achievement(
                    id: "master",
                    icon: "👑",
                    title: "Master of the Arena",
                    description: "Reached Master rank",
                    isUnlocked: true
                ))
            }
        
        // Submission-based achievements
        let acceptedCount = submissions.filter { $0.isAccepted }.count
        if acceptedCount >= 50 {
            result.append(Achievement(
                id: "soldier",
                icon: "⚔️",
                title: "Veteran Warrior",
                description: "Solved 50 problems",
                isUnlocked: true
            ))
        }
        
        if acceptedCount >= 100 {
            result.append(Achievement(
                id: "century",
                icon: "💯",
                title: "Centurion",
                description: "Solved 100 problems",
                isUnlocked: true
            ))
        }
        
        if acceptedCount >= 500 {
            result.append(Achievement(
                id: "legend",
                icon: "🏆",
                title: "Legendary Hero",
                description: "Solved 500 problems",
                isUnlocked: true
            ))
        }
        
        // Add some locked achievements for motivation
        if acceptedCount < 1000 {
            result.append(Achievement(
                id: "grandmaster_solver",
                icon: "⚡",
                title: "Grandmaster Solver",
                description: "Solve 1000 problems",
                isUnlocked: false
            ))
        }
        
        return result
    }
}

struct Achievement {
    let id: String
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool
}

struct AchievementCard: View {
    let achievement: Achievement
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            // Background with epic RPG styling
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: achievement.isUnlocked ? [
                            Color.ratingColor(for: 1600).opacity(0.15),
                            colorThemeManager.current.surface,
                            colorThemeManager.current.surface.opacity(0.8)
                        ] : [
                            colorThemeManager.current.surface.opacity(0.3),
                            colorThemeManager.current.surface.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Epic border effect
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: achievement.isUnlocked ? [
                                    Color.ratingColor(for: 1600).opacity(0.8),
                                    colorThemeManager.current.accent.opacity(0.6),
                                    Color.ratingColor(for: 1900).opacity(0.4)
                                ] : [
                                    colorThemeManager.current.divider.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: achievement.isUnlocked ? 2 : 1
                        )
                )
            
            // Content
            VStack(spacing: 12) {
                // Icon with glow effect for unlocked achievements
                ZStack {
                    if achievement.isUnlocked {
                        Circle()
                            .fill(Color.ratingColor(for: 1600).opacity(0.2))
                            .frame(width: 50, height: 50)
                            .blur(radius: 8)
                    }
                    
                    Text(achievement.icon)
                        .font(.system(size: 28))
                        .opacity(achievement.isUnlocked ? 1.0 : 0.4)
                        .scaleEffect(achievement.isUnlocked ? 1.1 : 0.9)
                }
                
                VStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.custom("TTPhobosTrial-Bold", size: 13))
                        .foregroundColor(achievement.isUnlocked ? colorThemeManager.current.textPrimary : colorThemeManager.current.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(.custom("TTPhobosTrial-Regular", size: 10))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // Status indicator
                if achievement.isUnlocked {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorThemeManager.current.successColor)
                            .frame(width: 6, height: 6)
                        
                        Text("UNLOCKED")
                            .font(.custom("TTPhobosTrial-Bold", size: 8))
                            .foregroundColor(colorThemeManager.current.successColor)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorThemeManager.current.textSecondary.opacity(0.5))
                            .frame(width: 6, height: 6)
                        
                        Text("LOCKED")
                            .font(.custom("TTPhobosTrial-Bold", size: 8))
                            .foregroundColor(colorThemeManager.current.textSecondary.opacity(0.7))
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
        }
        .scaleEffect(achievement.isUnlocked ? 1.02 : 0.98)
        .animation(.easeInOut(duration: 0.3), value: achievement.isUnlocked)
        .shadow(
            color: achievement.isUnlocked ? Color.ratingColor(for: 1600).opacity(0.3) : .clear,
            radius: achievement.isUnlocked ? 8 : 0,
            y: achievement.isUnlocked ? 4 : 0
        )
    }
}

// MARK: - Rating History Section
struct RatingHistorySection: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📜 Battle Chronicles")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Spacer()
                
                if !cfService.ratingHistory.isEmpty {
                    Text("\(cfService.ratingHistory.count) contests")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorThemeManager.current.accent.opacity(0.1))
                        )
                }
            }
            
            if cfService.ratingHistory.isEmpty {
                EmptyRatingHistoryView()
                    .frame(height: 200)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(cfService.ratingHistory.prefix(10), id: \.contestId) { ratingChange in
                        RatingHistoryCard(ratingChange: ratingChange)
                    }
                    
                    if cfService.ratingHistory.count > 10 {
                        Text("... and \(cfService.ratingHistory.count - 10) more contests")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.textSecondary)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.9))
                .stroke(colorThemeManager.current.divider, lineWidth: 1)
        )
    }
}

struct EmptyRatingHistoryView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📜")
                .font(.system(size: 48))
                .opacity(0.6)
            
            Text("No Battle Chronicle")
                .font(.custom("TTPhobosTrial-Bold", size: 16))
                .foregroundColor(colorThemeManager.current.textPrimary)
            
            Text("Your contest history will appear here once you participate in rated contests")
                .font(.custom("TTPhobosTrial-Regular", size: 14))
                .foregroundColor(colorThemeManager.current.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct RatingHistoryCard: View {
    let ratingChange: CFRatingChange
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var isVictory: Bool {
        ratingChange.newRating > ratingChange.oldRating
    }
    
    var body: some View {
        ZStack {
            // Epic card background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isVictory ? [
                            colorThemeManager.current.successColor.opacity(0.08),
                            colorThemeManager.current.surface,
                            colorThemeManager.current.surface.opacity(0.9)
                        ] : [
                            colorThemeManager.current.errorColor.opacity(0.08),
                            colorThemeManager.current.surface,
                            colorThemeManager.current.surface.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: isVictory ? [
                                    colorThemeManager.current.successColor.opacity(0.4),
                                    colorThemeManager.current.successColor.opacity(0.2)
                                ] : [
                                    colorThemeManager.current.errorColor.opacity(0.4),
                                    colorThemeManager.current.errorColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: isVictory ? 
                        colorThemeManager.current.successColor.opacity(0.2) : 
                        colorThemeManager.current.errorColor.opacity(0.2),
                    radius: 6,
                    y: 3
                )
            
            HStack(spacing: 16) {
                // Epic battle result indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isVictory ? [
                                    colorThemeManager.current.successColor.opacity(0.2),
                                    colorThemeManager.current.successColor.opacity(0.1)
                                ] : [
                                    colorThemeManager.current.errorColor.opacity(0.2),
                                    colorThemeManager.current.errorColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Text(isVictory ? "⬆️" : "⬇️")
                        .font(.system(size: 16))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "sword.fill")
                            .foregroundColor(colorThemeManager.current.accent)
                            .font(.system(size: 12))
                        
                        Text("Contest \(ratingChange.contestId)")
                            .font(.custom("TTPhobosTrial-Bold", size: 14))
                            .foregroundColor(colorThemeManager.current.textPrimary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Color.ratingColor(for: ratingChange.newRating))
                            .font(.system(size: 10))
                        
                        Text("Rank: \(ratingChange.rank)")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    // Rating change display with epic styling
                    HStack(spacing: 6) {
                        ZStack {
                            Text("\(ratingChange.oldRating)")
                                .font(.custom("TTPhobosTrial-Bold", size: 12))
                                .foregroundColor(Color.ratingColor(for: ratingChange.oldRating))
                                .opacity(0.7)
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(colorThemeManager.current.textSecondary)
                        
                        ZStack {
                            // Glow for new rating
                            Text("\(ratingChange.newRating)")
                                .font(.custom("TTPhobosTrial-Bold", size: 12))
                                .foregroundColor(Color.ratingColor(for: ratingChange.newRating))
                                .blur(radius: 2)
                                .opacity(0.3)
                            
                            Text("\(ratingChange.newRating)")
                                .font(.custom("TTPhobosTrial-Bold", size: 12))
                                .foregroundColor(Color.ratingColor(for: ratingChange.newRating))
                        }
                    }
                    
                    // Change amount with epic styling
                    HStack(spacing: 2) {
                        Text(isVictory ? "+" : "")
                        Text("\(ratingChange.newRating - ratingChange.oldRating)")
                    }
                    .font(.custom("TTPhobosTrial-Bold", size: 11))
                    .foregroundColor(isVictory ? colorThemeManager.current.successColor : colorThemeManager.current.errorColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(
                                (isVictory ? colorThemeManager.current.successColor : colorThemeManager.current.errorColor)
                                    .opacity(0.15)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isVictory ? colorThemeManager.current.successColor : colorThemeManager.current.errorColor,
                                        lineWidth: 0.5
                                    )
                                    .opacity(0.3)
                            )
                    )
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    NavigationView {
        RatingChartView()
    }
}
