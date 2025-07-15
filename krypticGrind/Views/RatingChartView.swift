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
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Power Level Title Bar
                    PowerLevelTitleBar()
                    
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

// MARK: - Power Level Title Bar
struct PowerLevelTitleBar: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("⚡")
                    .font(.system(size: 24))
                
                Text("Power Level")
                    .font(.custom("TTPhobosTrial-Bold", size: 24))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
                
                Text("📊")
                    .font(.system(size: 20))
            }
            
            HStack {
                if let handle = UserDefaults.standard.savedHandle {
                    Text("\(handle)'s Journey")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                } else {
                    Text("Rating Journey")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                }
                
                Spacer()
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

// MARK: - Power Level Header
struct PowerLevelHeader: View {
    let user: CFUser
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Power Level Display
            VStack(spacing: 8) {
                Text("⚡ Power Level")
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                
                HStack(spacing: 8) {
                    Text("\(user.rating)")
                        .font(.custom("TTPhobosTrial-Bold", size: 48))
                        .foregroundColor(Color.ratingColor(for: user.rating))
                    
                    Text(rankTitle)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.ratingColor(for: user.rating))
                        )
                }
                
                // Power Level Progress
                PowerLevelProgressBar(currentRating: user.rating)
            }
            
            // Rank Achievement Badges
            HStack(spacing: 12) {
                ForEach(achievedRanks, id: \.self) { rank in
                    RankBadge(rank: rank)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.ratingColor(for: user.rating).opacity(0.1),
                            colorThemeManager.current.surface.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .stroke(Color.ratingColor(for: user.rating), lineWidth: 1)
        )
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
        VStack(spacing: 8) {
            HStack {
                Text("Next Rank: \(nextRankTitle)")
                    .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                
                Spacer()
                
                Text("\(currentRating) / \(nextRankThreshold)")
                    .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    .foregroundColor(colorThemeManager.current.textSecondary)
            }
            
            ProgressView(value: progressToNextRank)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.ratingColor(for: currentRating)))
                .scaleEffect(y: 2)
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
        VStack(spacing: 16) {
            HStack {
                Text("📈 Power Level Journey")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Spacer()
                
                if !cfService.ratingHistory.isEmpty {
                    Text("\(cfService.ratingHistory.count) battles")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                }
            }
            
            // Enhanced Chart
            ZStack {
                if !cfService.ratingHistory.isEmpty {
                    Chart(cfService.ratingHistory, id: \.contestId) { ratingChange in
                        LineMark(
                            x: .value("Contest", ratingChange.ratingUpdateTimeSeconds),
                            y: .value("Rating", ratingChange.newRating)
                        )
                        .foregroundStyle(Color.ratingColor(for: ratingChange.newRating))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Contest", ratingChange.ratingUpdateTimeSeconds),
                            y: .value("Rating", ratingChange.newRating)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.ratingColor(for: ratingChange.newRating).opacity(0.3),
                                    Color.ratingColor(for: ratingChange.newRating).opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        if let selectedRating = selectedRating,
                           selectedRating.contestId == ratingChange.contestId {
                            RuleMark(x: .value("Contest", ratingChange.ratingUpdateTimeSeconds))
                                .foregroundStyle(colorThemeManager.current.accent)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        }
                    }
                    .frame(height: 250)
                    .chartXScale(domain: .automatic)
                    .chartYScale(domain: .automatic)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let rating = value.as(Int.self) {
                                    Text("\(rating)")
                                        .font(.custom("TTPhobosTrial-Regular", size: 10))
                                        .foregroundColor(colorThemeManager.current.textSecondary)
                                }
                            }
                        }
                    }
                    .chartAngleSelection(value: .constant(nil))
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
                        .frame(height: 250)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorThemeManager.current.surface.opacity(0.6))
            )
            
            // Selected Battle Details
            if let selectedRating = selectedRating {
                PowerLevelBattleDetails(ratingChange: selectedRating)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.9))
                .stroke(colorThemeManager.current.divider, lineWidth: 1)
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
        VStack(spacing: 16) {
            Text("📊")
                .font(.system(size: 48))
                .opacity(0.6)
            
            Text("No Power Level Data")
                .font(.custom("TTPhobosTrial-Bold", size: 16))
                .foregroundColor(colorThemeManager.current.textPrimary)
            
            Text("Participate in contests to see your power level journey")
                .font(.custom("TTPhobosTrial-Regular", size: 14))
                .foregroundColor(colorThemeManager.current.textSecondary)
                .multilineTextAlignment(.center)
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
        VStack(spacing: 16) {
            HStack {
                Text("🏅 Battle Achievements")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementCard(achievement: achievement)
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
        VStack(spacing: 8) {
            Text(achievement.icon)
                .font(.system(size: 32))
                .opacity(achievement.isUnlocked ? 1.0 : 0.3)
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    .foregroundColor(achievement.isUnlocked ? colorThemeManager.current.textPrimary : colorThemeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.custom("TTPhobosTrial-Regular", size: 10))
                    .foregroundColor(colorThemeManager.current.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(achievement.isUnlocked ? colorThemeManager.current.successColor.opacity(0.1) : colorThemeManager.current.surface.opacity(0.5))
                .stroke(achievement.isUnlocked ? colorThemeManager.current.successColor.opacity(0.3) : colorThemeManager.current.divider, lineWidth: 1)
        )
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: achievement.isUnlocked)
    }
}

// MARK: - Rating History Section
struct RatingHistorySection: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📜 Battle Chronicle")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Spacer()
                
                if !cfService.ratingHistory.isEmpty {
                    Text("\(cfService.ratingHistory.count) contests")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.textSecondary)
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Battle Result Icon
            Text(ratingChange.newRating > ratingChange.oldRating ? "⬆️" : "⬇️")
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Contest \(ratingChange.contestId)")
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(colorThemeManager.current.textPrimary)
                
                Text("Rank: \(ratingChange.rank)")
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(ratingChange.oldRating)")
                        .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                        .foregroundColor(Color.ratingColor(for: ratingChange.oldRating))
                    
                    Text("→")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.textSecondary)
                    
                    Text("\(ratingChange.newRating)")
                        .font(.custom("TTPhobosTrial-Bold", size: 12))
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorThemeManager.current.surface)
                .stroke(colorThemeManager.current.divider, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        RatingChartView()
    }
}
