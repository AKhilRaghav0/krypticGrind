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
                    LazyVStack(spacing: 16) {
                        // Header
                        RPGBattleHeader()
                            .padding(.horizontal, 20)
                        
                        // Filter Tabs
                        BattleFilterTabs(selectedFilter: $selectedFilter)
                            .padding(.horizontal, 20)
                        
                        // Battle Log Cards
                        ForEach(filteredSubmissions) { submission in
                            BattleLogCard(submission: submission)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer().frame(height: 50)
                    }
                    .padding(.top, 20)
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
        VStack(spacing: 12) {
            HStack {
                Text("⚔️")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Battle Chronicles")
                        .font(.custom("TTPhobosTrial-Bold", size: 28))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Text("Your coding quest history")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
                
                Spacer()
                
                Text("🏰")
                    .font(.system(size: 28))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Battle Filter Tabs
struct BattleFilterTabs: View {
    @Binding var selectedFilter: BattleLogsView.BattleFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BattleLogsView.BattleFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        HStack(spacing: 8) {
                            Text(filter.icon)
                                .font(.system(size: 16))
                            
                            Text(filter.rawValue)
                                .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        }
                        .foregroundColor(selectedFilter == filter ? .white : colorThemeManager.current.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? colorThemeManager.current.accent : colorThemeManager.current.surface.opacity(0.5))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Battle Log Card
struct BattleLogCard: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with battle result
            HStack {
                // Battle result icon
                ZStack {
                    Circle()
                        .fill(battleResultColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(battleIcon)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(submission.problem.name)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(colorThemeManager.current.text)
                        .lineLimit(1)
                    
                    Text("Problem \(submission.problem.index)")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(battleVerdict)
                        .font(.custom("TTPhobosTrial-Bold", size: 12))
                        .foregroundColor(battleResultColor)
                    
                    Text(submission.submissionDate.timeAgo())
                        .font(.custom("TTPhobosTrial-Regular", size: 10))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(battleResultColor.opacity(0.3), lineWidth: 1)
                )
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
}

#Preview {
    BattleLogsView()
        .environmentObject(ColorThemeManager())
}
