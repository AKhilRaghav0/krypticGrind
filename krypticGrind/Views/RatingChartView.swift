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
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Chart Section
                    RatingChart()
                    
                    // Stats Section
                    RatingStatsCard()
                    
                    // Contest History
                    ContestHistoryList()
                }
                .padding()
            }
            .background(themeManager.colors.background)
            .navigationTitle("Rating History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
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
                Label("Rating Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if cfService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if cfService.ratingHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 50))
                        .foregroundStyle(.tertiary)
                    
                    VStack(spacing: 8) {
                        Text("No Contest History")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Your rating changes will appear here after participating in contests")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(.tertiary.opacity(0.5))
                        AxisTick()
                            .foregroundStyle(.secondary)
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(.tertiary.opacity(0.5))
                        AxisTick()
                            .foregroundStyle(.secondary)
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .chartBackground { _ in
                    Color.clear
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct RatingStatsCard: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Statistics", systemImage: "chart.bar.fill")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
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
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 50))
                        .foregroundStyle(.tertiary)
                    
                    Text("No user data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ContestHistoryList: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Contest History", systemImage: "calendar")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            if cfService.ratingHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 50))
                        .foregroundStyle(.tertiary)
                    
                    VStack(spacing: 8) {
                        Text("No Contest History")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Your contest participation history will appear here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(cfService.ratingHistory.prefix(5).reversed()) { change in
                        ContestHistoryRow(change: change)
                    }
                    
                    if cfService.ratingHistory.count > 5 {
                        Button("View All \(cfService.ratingHistory.count) Contests") {
                            // Handle view all action
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(themeManager.colors.accent)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ContestHistoryRow: View {
    let change: CFRatingChange
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Contest info
            VStack(alignment: .leading, spacing: 4) {
                Text(change.contestName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label("Rank #\(change.rank)", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(change.updateDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Rating change
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: change.delta >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption.weight(.bold))
                    
                    Text(change.deltaString)
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(change.delta >= 0 ? .green : .red)
                
                Text("\(change.oldRating) → \(change.newRating)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationView {
        RatingChartView()
    }
}
