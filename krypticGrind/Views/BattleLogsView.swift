//
//  BattleLogsView.swift
//  KrypticGrind
//
//  Created for Hackathon - RPG Battle Logs
//

import SwiftUI

struct BattleLogsView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var selectedFilter: BattleFilter = .all

    
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
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // RPG Background
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Enhanced Header with Stats
                        VStack(spacing: 16) {
                            RPGBattleHeader()
                            
                            // Battle Stats Overview
                            BattleStatsBar()
                        }
                        .padding(.horizontal, 20)
                        
                        // Enhanced Filter Tabs
                        BattleFilterTabs(selectedFilter: $selectedFilter)
                            .padding(.horizontal, 20)
                        
                        // Battle Log Cards with better spacing
                        LazyVStack(spacing: 12) {
                            ForEach(Array(filteredSubmissions.enumerated()), id: \.element.id) { index, submission in
                                BattleLogCard(submission: submission, index: index)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var filteredSubmissions: [CFSubmission] {
        let submissions = cfService.recentSubmissions
        switch selectedFilter {
        case .all:
            return submissions
        case .victories:
            return submissions.filter { $0.isAccepted }
        case .defeats:
            return submissions.filter { !$0.isAccepted }
        case .recent:
            return Array(submissions.prefix(20))
        }
    }
}

// MARK: - RPG Battle Header
struct RPGBattleHeader: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Title Section
            HStack(alignment: .center, spacing: 16) {
                // Left Icon with glow effect
                ZStack {
                    Circle()
                        .fill(colorThemeManager.current.accent.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Text("⚔️")
                        .font(.system(size: 28))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Battle Chronicles")
                        .font(.custom("TTPhobosTrial-Bold", size: 32))
                        .foregroundColor(colorThemeManager.current.text)
                        .lineLimit(1)
                    
                    Text("Track your coding conquests")
                        .font(.custom("TTPhobosTrial-Regular", size: 16))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                }
                
                Spacer()
                
                // Right decorative element
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorThemeManager.current.accent.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Text("🏰")
                        .font(.system(size: 24))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorThemeManager.current.surface.opacity(0.9),
                            colorThemeManager.current.surface.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
        )
        .shadow(color: colorThemeManager.current.accent.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Battle Stats Bar
struct BattleStatsBar: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Victories
            StatCard(
                title: "Victories",
                value: "\(victoryCount)",
                icon: "🏆",
                color: .green
            )
            
            // Defeats
            StatCard(
                title: "Defeats", 
                value: "\(defeatCount)",
                icon: "💀",
                color: .red
            )
            
            // Win Rate
            StatCard(
                title: "Win Rate",
                value: "\(winRate)%",
                icon: "📊",
                color: colorThemeManager.current.accent
            )
        }
    }
    
    private var victoryCount: Int {
        cfService.recentSubmissions.filter { $0.isAccepted }.count
    }
    
    private var defeatCount: Int {
        cfService.recentSubmissions.filter { !$0.isAccepted }.count
    }
    
    private var winRate: Int {
        let total = cfService.recentSubmissions.count
        guard total > 0 else { return 0 }
        return Int((Double(victoryCount) / Double(total)) * 100)
    }
}

// MARK: - Stat Card
struct StatCard: View {
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

// MARK: - Battle Filter Tabs
struct BattleFilterTabs: View {
    @Binding var selectedFilter: BattleLogsView.BattleFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Title
            Text("Filter Battles")
                .font(.custom("TTPhobosTrial-Bold", size: 18))
                .foregroundColor(colorThemeManager.current.text)
                .padding(.horizontal, 4)
            
            // Filter Options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BattleLogsView.BattleFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            HStack(spacing: 10) {
                                Text(filter.icon)
                                    .font(.system(size: 16))
                                
                                Text(filter.rawValue)
                                    .font(.custom("TTPhobosTrial-DemiBold", size: 15))
                            }
                            .foregroundColor(selectedFilter == filter ? .white : colorThemeManager.current.text)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(
                                        selectedFilter == filter 
                                        ? LinearGradient(
                                            gradient: Gradient(colors: [
                                                colorThemeManager.current.accent,
                                                colorThemeManager.current.accent.opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            gradient: Gradient(colors: [
                                                colorThemeManager.current.surface.opacity(0.7),
                                                colorThemeManager.current.surface.opacity(0.5)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                                            .stroke(
                                                selectedFilter == filter 
                                                ? colorThemeManager.current.accent.opacity(0.3)
                                                : colorThemeManager.current.text.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .shadow(
                            color: selectedFilter == filter 
                            ? colorThemeManager.current.accent.opacity(0.3) 
                            : .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Battle Log Card
struct BattleLogCard: View {
    let submission: CFSubmission
    let index: Int
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            VStack(spacing: 16) {
                // Header Row
                HStack(alignment: .center, spacing: 16) {
                    // Battle Result Icon with enhanced styling
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        battleResultColor.opacity(0.2),
                                        battleResultColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .stroke(battleResultColor.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 50, height: 50)
                        
                        Text(battleIcon)
                            .font(.system(size: 22))
                    }
                    
                    // Problem Details
                    VStack(alignment: .leading, spacing: 6) {
                        Text(submission.problem.name)
                            .font(.custom("TTPhobosTrial-Bold", size: 17))
                            .foregroundColor(colorThemeManager.current.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            Text("Problem \(submission.problem.index)")
                                .font(.custom("TTPhobosTrial-Regular", size: 13))
                                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            
                            Text("•")
                                .font(.custom("TTPhobosTrial-Regular", size: 13))
                                .foregroundColor(colorThemeManager.current.text.opacity(0.3))
                            
                            Text(difficultyLevel)
                                .font(.custom("TTPhobosTrial-DemiBold", size: 13))
                                .foregroundColor(difficultyColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Battle Result & Time
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(battleVerdict)
                            .font(.custom("TTPhobosTrial-Bold", size: 13))
                            .foregroundColor(battleResultColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(battleResultColor.opacity(0.1))
                            )
                        
                        Text(submission.submissionDate.timeAgo())
                            .font(.custom("TTPhobosTrial-Regular", size: 11))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                    }
                }
                
                // Battle Stats Row
                HStack(spacing: 20) {
                    // Time Taken
                    HStack(spacing: 6) {
                        Text("⏱️")
                            .font(.system(size: 12))
                        Text("Quick Strike")
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Language Badge
                    HStack(spacing: 6) {
                        Text("⚡")
                            .font(.system(size: 12))
                        Text(submission.language ?? "Unknown")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(colorThemeManager.current.accent.opacity(0.1))
                    )
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorThemeManager.current.surface.opacity(0.8),
                            colorThemeManager.current.surface.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    battleResultColor.opacity(0.3),
                                    battleResultColor.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(
            color: battleResultColor.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
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
    
    private var difficultyLevel: String {
        // Mock difficulty based on problem rating or index
        if submission.problem.rating > 2000 {
            return "Expert"
        } else if submission.problem.rating > 1500 {
            return "Advanced"
        } else if submission.problem.rating > 1000 {
            return "Intermediate"
        } else {
            return "Beginner"
        }
    }
    
    private var difficultyColor: Color {
        switch difficultyLevel {
        case "Expert": return .red
        case "Advanced": return .orange
        case "Intermediate": return .blue
        default: return .green
        }
    }
}

#Preview {
    BattleLogsView()
        .environmentObject(ColorThemeManager())
}
