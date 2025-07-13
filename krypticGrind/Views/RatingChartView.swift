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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Chart Section
                        RatingChart()
                        
                        // Stats Section
                        RatingStatsCard()
                        
                        // Contest History
                        ContestHistoryList()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Rating History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(themeManager.colors.accent)
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchRatingHistory(handle: handle)
            }
        }
    }
}

struct RatingChart: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rating Progress")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(themeManager.colors.textPrimary)
                
                Spacer()
                
                if cfService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if cfService.ratingHistory.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(themeManager.colors.textSecondary)
                    
                    VStack(spacing: 8) {
                        Text("No Contest History")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(themeManager.colors.textPrimary)
                        
                        Text("Your rating changes will appear here after participating in contests")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(themeManager.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(cfService.ratingHistory) { change in
                        LineMark(
                            x: .value("Date", change.updateDate),
                            y: .value("Rating", change.newRating)
                        )
                        .foregroundStyle(themeManager.colors.accent.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        
                        AreaMark(
                            x: .value("Date", change.updateDate),
                            y: .value("Rating", change.newRating)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.colors.accent.opacity(0.3), themeManager.colors.accent.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        PointMark(
                            x: .value("Date", change.updateDate),
                            y: .value("Rating", change.newRating)
                        )
                        .foregroundStyle(themeManager.colors.accent)
                        .symbolSize(25)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(themeManager.colors.textSecondary.opacity(0.3))
                        AxisTick()
                            .foregroundStyle(themeManager.colors.textSecondary)
                        AxisValueLabel()
                            .foregroundStyle(themeManager.colors.textSecondary)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(themeManager.colors.textSecondary.opacity(0.3))
                        AxisTick()
                            .foregroundStyle(themeManager.colors.textSecondary)
                        AxisValueLabel()
                            .foregroundStyle(themeManager.colors.textSecondary)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .chartBackground { _ in
                    Color.clear
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
    }
}

struct RatingStatsCard: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(themeManager.colors.textPrimary)
            
            if let user = cfService.currentUser {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ModernStatCard(
                        title: "Current Rating",
                        value: "\(user.rating)",
                        icon: "star.fill",
                        color: Color.ratingColor(for: user.rating),
                        subtitle: user.rank
                    )
                    
                    ModernStatCard(
                        title: "Max Rating",
                        value: "\(user.maxRating)",
                        icon: "trophy.fill",
                        color: Color.ratingColor(for: user.maxRating),
                        subtitle: user.maxRank
                    )
                    
                    if !cfService.ratingHistory.isEmpty {
                        ModernStatCard(
                            title: "Contests",
                            value: "\(cfService.ratingHistory.count)",
                            icon: "calendar",
                            color: themeManager.colors.accent,
                            subtitle: "participated"
                        )
                        
                        if let bestChange = cfService.ratingHistory.max(by: { $0.delta < $1.delta }) {
                            ModernStatCard(
                                title: "Best Gain",
                                value: bestChange.deltaString,
                                icon: "arrow.up.circle.fill",
                                color: .green,
                                subtitle: "in one contest"
                            )
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(themeManager.colors.textSecondary)
                    
                    VStack(spacing: 8) {
                        Text("No User Data")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(themeManager.colors.textPrimary)
                        
                        Text("Enter your Codeforces handle to see statistics")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(themeManager.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(themeManager.colors.textPrimary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.colors.textSecondary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(themeManager.colors.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

struct ContestHistoryList: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Contests")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(themeManager.colors.textPrimary)
            
            if cfService.ratingHistory.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(themeManager.colors.textSecondary)
                    
                    VStack(spacing: 8) {
                        Text("No Contest History")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(themeManager.colors.textPrimary)
                        
                        Text("Participate in contests to see your history here")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(themeManager.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(cfService.ratingHistory.prefix(10)) { change in
                        ContestHistoryCard(change: change)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
    }
}

struct ContestHistoryCard: View {
    let change: CFRatingChange
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Contest info
            VStack(alignment: .leading, spacing: 4) {
                Text(change.contestName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager.colors.textPrimary)
                    .lineLimit(1)
                
                Text(change.updateDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(themeManager.colors.textSecondary)
            }
            
            Spacer()
            
            // Rating change
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(change.oldRating)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(themeManager.colors.textSecondary)
                    
                    Image(systemName: change.delta > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(change.delta > 0 ? .green : .red)
                    
                    Text("\(change.newRating)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(themeManager.colors.textPrimary)
                }
                
                Text(change.deltaString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(change.delta > 0 ? .green : .red)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

#Preview {
    NavigationView {
        RatingChartView()
    }
}
