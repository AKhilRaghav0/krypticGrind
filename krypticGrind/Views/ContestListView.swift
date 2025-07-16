//
//  ContestListView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//  Enhanced with contest problems display, analytics, and improved UX
//

import SwiftUI
import ActivityKit

struct ContestListView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var selectedArena: ArenaType = .upcoming
    
    enum ArenaType: String, CaseIterable {
        case upcoming = "Upcoming Battles"
        case recent = "Past Conquests"
        
        var icon: String {
            switch self {
            case .upcoming: return "⚔️"
            case .recent: return "🏆"
            }
        }
        
        var dungeonTitle: String {
            switch self {
            case .upcoming: return "Battle Arena"
            case .recent: return "Hall of Legends"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Dungeon Header
                    ContestDungeonHeader(selectedArena: $selectedArena)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .background(colorThemeManager.current.background)
                        .zIndex(1)
                    
                    // Content
                    TabView(selection: $selectedArena) {
                        UpcomingBattlesView()
                            .tag(ArenaType.upcoming)
                        
                        PastConquestsView()
                            .tag(ArenaType.recent)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .clipped()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .tint(colorThemeManager.current.accent)
        .task {
            await cfService.fetchContests()
        }
    }
}

struct ContestToggle: View {
    @Binding var showingFinished: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                showingFinished = false
            }) {
                Text("Upcoming")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(showingFinished ? colorThemeManager.current.text.opacity(0.6) : colorThemeManager.current.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(showingFinished ? colorThemeManager.current.tabBar.opacity(0.9) : colorThemeManager.current.accent)
                            .shadow(color: showingFinished ? Color.black.opacity(0.05) : colorThemeManager.current.accent.opacity(0.3), radius: 8, y: 2)
                    )
            }
            
            Button(action: {
                showingFinished = true
            }) {
                Text("Recent")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(showingFinished ? colorThemeManager.current.text : colorThemeManager.current.text.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(showingFinished ? colorThemeManager.current.accent : colorThemeManager.current.tabBar.opacity(0.9))
                            .shadow(color: showingFinished ? colorThemeManager.current.accent.opacity(0.3) : Color.black.opacity(0.05), radius: 8, y: 2)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingFinished)
    }
}

struct UpcomingContestsList: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Show error with retry button if there's an error
                if let error = cfService.error {
                    ErrorRetryView(
                        message: error,
                        isLoading: cfService.isLoading,
                        onRetry: {
                            Task {
                                await cfService.retryLastOperation()
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                } else if cfService.upcomingContests.isEmpty && !cfService.isLoading {
                    EmptyContestsView(isUpcoming: true)
                } else {
                    ForEach(cfService.upcomingContests) { contest in
                        UpcomingContestCard(contest: contest)
                    }
                }
                
                // Loading indicator
                if cfService.isLoading {
                    ProgressView("Loading contests...")
                        .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                        .padding()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}

struct FinishedContestsList: View {
    @StateObject private var cfService = CFService.shared
    @State private var finishedContests: [CFContest] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if finishedContests.isEmpty {
                    EmptyContestsView(isUpcoming: false)
                } else {
                    ForEach(finishedContests.prefix(20)) { contest in
                        FinishedContestCard(contest: contest)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .task {
            await loadFinishedContests()
        }
    }
    
    private func loadFinishedContests() async {
        do {
            let url = URL(string: "https://codeforces.com/api/contest.list")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CFContestResponse.self, from: data)
            
            if response.status == "OK" {
                finishedContests = response.result
                    .filter { $0.isFinished }
                    .sorted { 
                        guard let start1 = $0.startTimeSeconds, let start2 = $1.startTimeSeconds else { 
                            return false 
                        }
                        return start1 > start2 
                    }
            }
        } catch {
            print("Failed to fetch finished contests: \(error)")
        }
    }
}

struct UpcomingContestCard: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var showingLiveSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with contest info
            VStack(alignment: .leading, spacing: 8) {
                Text(contest.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(colorThemeManager.current.text)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    ContestTypeBadge(type: contest.type)
                    if let country = contest.country {
                        ContestCountryBadge(country: country)
                    }
                    ContestPhaseBadge(phase: contest.phase)
                }
            }
            
            // Contest details
            HStack(spacing: 16) {
                DetailItem(
                    icon: "calendar",
                    text: contest.startDate?.formatted(date: .abbreviated, time: .shortened) ?? "TBD",
                    color: colorThemeManager.current.text.opacity(0.6)
                )
                
                DetailItem(
                    icon: "clock",
                    text: contest.duration,
                    color: colorThemeManager.current.text.opacity(0.6)
                )
                
                DetailItem(
                    icon: "person.3",
                    text: contest.type.capitalized,
                    color: colorThemeManager.current.text.opacity(0.6)
                )
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Primary notification button with haptic feedback
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    scheduleMultipleReminders()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 15, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notify Me")
                                .font(.custom("TTPhobosTrial-Bold", size: 14))
                            Text("Multi alerts")
                                .font(.custom("TTPhobosTrial-Regular", size: 11))
                                .opacity(0.8)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Details button with improved styling
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingLiveSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        
                        Text("Details")
                            .font(.custom("TTPhobosTrial-Bold", size: 14))
                    }
                    .foregroundStyle(colorThemeManager.current.text)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(colorThemeManager.current.tabBar.opacity(0.8))
                            .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Phase-specific action button with enhanced styling
                if contest.phase == "CODING" {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                        if let url = URL(string: contest.contestUrl) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Join Live")
                                    .font(.custom("TTPhobosTrial-Bold", size: 14))
                                Text("Running now")
                                    .font(.custom("TTPhobosTrial-Regular", size: 11))
                                    .opacity(0.8)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                } else if contest.phase == "BEFORE" {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        scheduleLastMinuteAlert()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 15, weight: .semibold))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Set Alert")
                                    .font(.custom("TTPhobosTrial-Bold", size: 14))
                                Text("5min before")
                                    .font(.custom("TTPhobosTrial-Regular", size: 11))
                                    .opacity(0.8)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [colorThemeManager.current.accent, colorThemeManager.current.accent.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: colorThemeManager.current.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
        .sheet(isPresented: $showingLiveSheet) {
            LiveContestSheet(contest: contest)
        }
    }
    
    private func scheduleMultipleReminders() {
        guard let startDate = contest.startDate else { return }
        
        // 1 day before
        let oneDayBefore = startDate.addingTimeInterval(-24 * 60 * 60)
        if oneDayBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Contest Tomorrow! 📅",
                body: "\(contest.name) starts tomorrow",
                date: oneDayBefore,
                identifier: "contest_\(contest.id)_1day"
            )
        }
        
        // 1 hour before
        let oneHourBefore = startDate.addingTimeInterval(-60 * 60)
        if oneHourBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Contest Starting Soon! ⚔️",
                body: "\(contest.name) starts in 1 hour",
                date: oneHourBefore,
                identifier: "contest_\(contest.id)_1hour"
            )
        }
        
        // 15 minutes before
        let fifteenMinBefore = startDate.addingTimeInterval(-15 * 60)
        if fifteenMinBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Final Call! 🔔",
                body: "\(contest.name) starts in 15 minutes!",
                date: fifteenMinBefore,
                identifier: "contest_\(contest.id)_15min"
            )
        }
    }
    
    private func scheduleLastMinuteAlert() {
        guard let startDate = contest.startDate else { return }
        
        // 5 minutes before
        let fiveMinBefore = startDate.addingTimeInterval(-5 * 60)
        if fiveMinBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Battle Alert! ⚡",
                body: "\(contest.name) starts in 5 minutes!",
                date: fiveMinBefore,
                identifier: "contest_\(contest.id)_alert"
            )
        }
    }
}

struct ContestTypeBadge: View {
    let type: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Text(type.capitalized)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(colorThemeManager.current.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorThemeManager.current.accent)
            )
    }
}

struct ContestCountryBadge: View {
    let country: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Text(country)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(colorThemeManager.current.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(colorThemeManager.current.text.opacity(0.6))
            )
    }
}

struct ContestPhaseBadge: View {
    let phase: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Text(phaseDisplayText)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(colorThemeManager.current.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(phaseColor)
            )
    }
    
    private var phaseDisplayText: String {
        switch phase {
        case "BEFORE": return "Upcoming"
        case "CODING": return "Running"
        case "PENDING_SYSTEM_TEST": return "Pending Tests"
        case "SYSTEM_TEST": return "System Test"
        case "FINISHED": return "Finished"
        default: return phase
        }
    }
    
    private var phaseColor: Color {
        switch phase {
        case "BEFORE": return colorThemeManager.current.accent
        case "CODING": return Color.green
        case "PENDING_SYSTEM_TEST": return Color.orange
        case "SYSTEM_TEST": return Color.orange
        case "FINISHED": return colorThemeManager.current.text.opacity(0.6)
        default: return colorThemeManager.current.text.opacity(0.6)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(colorThemeManager.current.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DetailItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

struct ContestInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(colorThemeManager.current.text)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(colorThemeManager.current.text.opacity(0.6).opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct FinishedContestCard: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contest.name)
                        .font(.headline.bold())
                        .foregroundStyle(colorThemeManager.current.text)
                        .lineLimit(2)
                    
                    if let startDate = contest.startDate {
                        Text("Held on \(startDate.formatted())")
                            .font(.subheadline)
                            .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Text("Finished")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorThemeManager.current.text.opacity(0.6).opacity(0.2))
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                    .cornerRadius(6)
            }
            
            HStack(spacing: 20) {
                ContestInfoItem(
                    title: "Duration",
                    value: contest.duration,
                    icon: "clock"
                )
                
                ContestInfoItem(
                    title: "Type",
                    value: contest.type.capitalized,
                    icon: "tag"
                )
                
                Spacer()
                
                Button(action: {
                    if let url = URL(string: contest.contestUrl) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("View", systemImage: "link")
                        .font(.caption.bold())
                        .foregroundStyle(colorThemeManager.current.accent)
                }
            }
        }
        .padding()
        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ContestInfoItem: View {
    let title: String
    let value: String
    let icon: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(colorThemeManager.current.text)
            }
        }
    }
}

struct EmptyContestsView: View {
    let isUpcoming: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isUpcoming ? "calendar" : "checkmark.circle")
                .font(.system(size: 50))
                .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
            
            Text(isUpcoming ? "No upcoming contests" : "Loading recent contests...")
                .font(.title3.bold())
                .foregroundStyle(colorThemeManager.current.text)
            
            Text(isUpcoming ? 
                 "Check back later for new contests" : 
                 "Please wait while we fetch contest data"
            )
                .font(.subheadline)
                .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ContestDetailSheet: View {
    let contest: CFContest
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Contest Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text(contest.name)
                                .font(.title2.bold())
                                .foregroundStyle(colorThemeManager.current.text)
                            
                            HStack {
                                Text(contest.phaseDisplayText)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(contest.phaseColorValue.opacity(0.2))
                                    .foregroundStyle(contest.phaseColorValue)
                                    .cornerRadius(8)
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Contest Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline.bold())
                                .foregroundStyle(colorThemeManager.current.text)
                            
                            if let startDate = contest.startDate {
                                InfoRow(title: "Start Time", value: startDate.formatted())
                            }
                            
                            if let endDate = contest.endDate {
                                InfoRow(title: "End Time", value: endDate.formatted())
                            }
                            
                            InfoRow(title: "Duration", value: contest.duration)
                            InfoRow(title: "Type", value: contest.type)
                            
                            if let difficulty = contest.difficulty {
                                InfoRow(title: "Difficulty", value: "\(difficulty)")
                            }
                            
                            if let preparedBy = contest.preparedBy {
                                InfoRow(title: "Prepared By", value: preparedBy)
                            }
                        }
                        .padding()
                        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Description
                        if let description = contest.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.headline.bold())
                                    .foregroundStyle(colorThemeManager.current.text)
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                            }
                            .padding()
                            .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Action Button
                        Button(action: {
                            if let url = URL(string: contest.contestUrl) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Open in Codeforces", systemImage: "link")
                                .font(.headline.bold())
                                .foregroundStyle(colorThemeManager.current.text)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colorThemeManager.current.accent)
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Contest Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(colorThemeManager.current.accent)
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Error Retry View
struct ErrorRetryView: View {
    let message: String
    let isLoading: Bool
    let onRetry: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Oops!")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isLoading ? "Retrying..." : "Retry")
                }
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(colorThemeManager.current.accent)
                .cornerRadius(12)
            }
            .disabled(isLoading)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Contest Dungeon Header
struct ContestDungeonHeader: View {
    @Binding var selectedArena: ContestListView.ArenaType
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Title
            Text("The Arena")
                .font(.custom("TTPhobosTrial-Bold", size: 28))
                .foregroundColor(colorThemeManager.current.text)
                .padding(.top, 8)
            
            // Arena Selector with Sliding Glass Effect
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorThemeManager.current.tabBar.opacity(0.3))
                    .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1)
                
                // Sliding glass background
                GeometryReader { geometry in
                    let tabWidth = geometry.size.width / CGFloat(ContestListView.ArenaType.allCases.count)
                    let selectedIndex = ContestListView.ArenaType.allCases.firstIndex(of: selectedArena) ?? 0
                    
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorThemeManager.current.tabBar.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1.5)
                        )
                        .frame(width: tabWidth - 8)
                        .offset(x: CGFloat(selectedIndex) * tabWidth + 4)
                        .shadow(color: colorThemeManager.current.accent.opacity(0.3), radius: 8, x: 0, y: 2)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: selectedArena)
                }
                
                // Arena buttons
                HStack(spacing: 0) {
                    ForEach(ContestListView.ArenaType.allCases, id: \.self) { arena in
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                                selectedArena = arena
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(arena.icon)
                                    .font(.system(size: selectedArena == arena ? 26 : 24))
                                    .scaleEffect(selectedArena == arena ? 1.1 : 1.0)
                                
                                Text(arena.dungeonTitle)
                                    .font(.custom("TTPhobosTrial-DemiBold", size: selectedArena == arena ? 17 : 16))
                                    .foregroundColor(
                                        selectedArena == arena ? 
                                        colorThemeManager.current.text : 
                                        colorThemeManager.current.text.opacity(0.6)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0), value: selectedArena)
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal, 4)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Upcoming Battles View
struct UpcomingBattlesView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if cfService.isLoading {
                    BattleLoadingView()
                        .padding(.top, 20)
                } else if cfService.upcomingContests.isEmpty {
                    EmptyBattlesView()
                        .padding(.top, 40)
                } else {
                    ForEach(cfService.upcomingContests, id: \.id) { contest in
                        BattleCard(contest: contest)
                    }
                }
                
                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .refreshable {
            await cfService.fetchContests()
        }
    }
}

// MARK: - Past Conquests View
struct PastConquestsView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var finishedContests: [CFContest] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    BattleLoadingView()
                        .padding(.top, 20)
                } else if finishedContests.isEmpty {
                    EmptyConquestsView()
                        .padding(.top, 40)
                } else {
                    ForEach(finishedContests, id: \.id) { contest in
                        ConquestCard(contest: contest)
                    }
                }
                
                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .task {
            await loadFinishedContests()
        }
        .refreshable {
            await loadFinishedContests()
        }
    }
    
    private func loadFinishedContests() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URL(string: "https://codeforces.com/api/contest.list")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CFContestResponse.self, from: data)
            
            if response.status == "OK" {
                finishedContests = response.result
                    .filter { $0.isFinished }
                    .sorted { 
                        guard let start1 = $0.startTimeSeconds, let start2 = $1.startTimeSeconds else { 
                            return false 
                        }
                        return start1 > start2 
                    }
                    .prefix(20)
                    .map { $0 }
            }
        } catch {
            print("Failed to fetch finished contests: \(error)")
        }
    }
}

// MARK: - Battle Card (Upcoming Contest)
struct BattleCard: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var showingLiveSheet = false
    @State private var showingAnalysisSheet = false
    @State private var timeUntilStart: String = ""
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with battle info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("⚔️")
                        .font(.system(size: 20))
                    
                    Text(contest.name)
                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                        .foregroundColor(colorThemeManager.current.text)
                        .lineLimit(2)
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    BattleTypeBadge(type: contest.type)
                    BattleDifficultyBadge(phase: contest.phase)
                    BattleDurationBadge(duration: contest.durationSeconds)
                }
            }
            
            // Battle timing info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(colorThemeManager.current.accent)
                        .font(.system(size: 14))
                    
                    if let startDate = contest.startDate {
                        Text(startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                            .foregroundColor(colorThemeManager.current.text)
                    } else {
                        Text("Time TBA")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    
                    Spacer()
                }
                
                // Countdown
                if !timeUntilStart.isEmpty {
                    HStack {
                        Text("⏳")
                            .font(.system(size: 14))
                        
                        Text("Starts in: \(timeUntilStart)")
                            .font(.custom("TTPhobosTrial-Regular", size: 13))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Enhanced Details button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Show different sheets based on contest phase
                    if contest.phase == "FINISHED" {
                        showingAnalysisSheet = true
                    } else {
                        showingLiveSheet = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Details")
                                .font(.custom("TTPhobosTrial-Bold", size: 14))
                            Text("Full info")
                                .font(.custom("TTPhobosTrial-Regular", size: 11))
                                .opacity(0.8)
                        }
                    }
                    .foregroundColor(colorThemeManager.current.text)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(colorThemeManager.current.tabBar.opacity(0.8))
                            .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Enhanced notification button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    scheduleContestNotifications()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 15, weight: .semibold))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notify Me")
                                .font(.custom("TTPhobosTrial-Bold", size: 14))
                            Text("Smart alerts")
                                .font(.custom("TTPhobosTrial-Regular", size: 11))
                                .opacity(0.8)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Phase-specific action button with enhanced styling
                if contest.phase == "CODING" {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                        if let url = URL(string: contest.contestUrl) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Join Live")
                                    .font(.custom("TTPhobosTrial-Bold", size: 14))
                                Text("Battle now!")
                                    .font(.custom("TTPhobosTrial-Regular", size: 11))
                                    .opacity(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                } else if contest.phase == "BEFORE" {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        scheduleLastMinuteReminder()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 15, weight: .semibold))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Remind")
                                    .font(.custom("TTPhobosTrial-Bold", size: 14))
                                Text("Final alert")
                                    .font(.custom("TTPhobosTrial-Regular", size: 11))
                                    .opacity(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [colorThemeManager.current.accent, colorThemeManager.current.accent.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: colorThemeManager.current.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                } else {
                    // For finished contests - space for future features
                    Spacer()
                        .frame(width: 0)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1)
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
        .onAppear {
            startCountdownTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showingLiveSheet) {
            LiveContestSheet(contest: contest)
        }
        .sheet(isPresented: $showingAnalysisSheet) {
            BattleAnalysisSheet(contest: contest)
        }
    }
    
    private func scheduleContestNotifications() {
        guard let startDate = contest.startDate else { return }
        
        // Schedule multiple notifications
        // 1 day before
        let oneDayBefore = startDate.addingTimeInterval(-24 * 60 * 60)
        if oneDayBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Contest Tomorrow! 📅",
                body: "\(contest.name) starts tomorrow at \(startDate.formatted(date: .omitted, time: .shortened))",
                date: oneDayBefore,
                identifier: "contest_\(contest.id)_1day"
            )
        }
        
        // 1 hour before
        let oneHourBefore = startDate.addingTimeInterval(-60 * 60)
        if oneHourBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Contest Starting Soon! ⚔️",
                body: "\(contest.name) starts in 1 hour. Get ready!",
                date: oneHourBefore,
                identifier: "contest_\(contest.id)_1hour"
            )
        }
        
        // 15 minutes before
        let fifteenMinBefore = startDate.addingTimeInterval(-15 * 60)
        if fifteenMinBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Final Call! 🔔",
                body: "\(contest.name) starts in 15 minutes!",
                date: fifteenMinBefore,
                identifier: "contest_\(contest.id)_15min"
            )
        }
        
        // Show confirmation
        // Note: In a real app, you might want to show a toast or alert
        print("Scheduled notifications for \(contest.name)")
    }
    
    private func scheduleLastMinuteReminder() {
        guard let startDate = contest.startDate else { return }
        
        // 5 minutes before
        let fiveMinBefore = startDate.addingTimeInterval(-5 * 60)
        if fiveMinBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Contest Alert! ⚡",
                body: "\(contest.name) starts in 5 minutes! Time to battle!",
                date: fiveMinBefore,
                identifier: "contest_\(contest.id)_5min"
            )
        }
        
        print("Scheduled last-minute reminder for \(contest.name)")
    }
    
    private func startCountdownTimer() {
        updateTimeUntilStart()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateTimeUntilStart()
        }
    }
    
    private func updateTimeUntilStart() {
        guard let startDate = contest.startDate else {
            timeUntilStart = ""
            return
        }
        
        let now = Date()
        let timeInterval = startDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            timeUntilStart = "Battle has begun!"
            timer?.invalidate()
        } else {
            let days = Int(timeInterval) / (24 * 3600)
            let hours = Int(timeInterval) % (24 * 3600) / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            
            if days > 0 {
                timeUntilStart = "\(days)d \(hours)h"
            } else if hours > 0 {
                timeUntilStart = "\(hours)h \(minutes)m"
            } else {
                timeUntilStart = "\(minutes)m"
            }
        }
    }
}

// MARK: - Conquest Card (Finished Contest)
struct ConquestCard: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var showingAnalysisSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with conquest info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🏆")
                        .font(.system(size: 20))
                    
                    Text(contest.name)
                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                        .foregroundColor(colorThemeManager.current.text)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text("CONQUERED")
                        .font(.custom("TTPhobosTrial-Bold", size: 10))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.1))
                        )
                }
                
                HStack(spacing: 12) {
                    ConquestTypeBadge(type: contest.type)
                    ConquestDurationBadge(duration: contest.durationSeconds)
                }
            }
            
            // Conquest timing info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundColor(colorThemeManager.current.accent)
                        .font(.system(size: 14))
                    
                    if let startDate = contest.startDate {
                        Text("Conquered on \(startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.custom("TTPhobosTrial-Regular", size: 14))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Warrior count info removed as participantCount not available in API
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Details button for analysis
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingAnalysisSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                        Text("Details")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [colorThemeManager.current.accent, colorThemeManager.current.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.7))
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                .shadow(color: Color.green.opacity(0.08), radius: 8, y: 2)
        )
        .sheet(isPresented: $showingAnalysisSheet) {
            BattleAnalysisSheet(contest: contest)
        }
    }
}

// MARK: - Badge Components
struct BattleTypeBadge: View {
    let type: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text(typeIcon)
                .font(.system(size: 12))
            Text(type.uppercased())
                .font(.custom("TTPhobosTrial-Bold", size: 10))
                .foregroundColor(typeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(typeColor.opacity(0.1))
        )
    }
    
    private var typeIcon: String {
        switch type.lowercased() {
        case "cf": return "⚡"
        case "icpc": return "🏅"
        case "ioi": return "🎯"
        default: return "⚔️"
        }
    }
    
    private var typeColor: Color {
        switch type.lowercased() {
        case "cf": return .blue
        case "icpc": return .orange
        case "ioi": return .purple
        default: return colorThemeManager.current.accent
        }
    }
}

struct BattleDifficultyBadge: View {
    let phase: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text(phaseIcon)
                .font(.system(size: 12))
            Text(phase.uppercased())
                .font(.custom("TTPhobosTrial-Bold", size: 10))
                .foregroundColor(phaseColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(phaseColor.opacity(0.1))
        )
    }
    
    private var phaseIcon: String {
        switch phase.lowercased() {
        case "before": return "⏰"
        case "coding": return "💻"
        case "finished": return "✅"
        default: return "📋"
        }
    }
    
    private var phaseColor: Color {
        switch phase.lowercased() {
        case "before": return .orange
        case "coding": return .green
        case "finished": return .gray
        default: return colorThemeManager.current.accent
        }
    }
}

struct BattleDurationBadge: View {
    let duration: Int
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text("⏱️")
                .font(.system(size: 12))
            Text(durationText)
                .font(.custom("TTPhobosTrial-Bold", size: 10))
                .foregroundColor(colorThemeManager.current.text.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorThemeManager.current.text.opacity(0.1))
        )
    }
    
    private var durationText: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct ConquestTypeBadge: View {
    let type: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text(typeIcon)
                .font(.system(size: 12))
            Text(type.uppercased())
                .font(.custom("TTPhobosTrial-Bold", size: 10))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    private var typeIcon: String {
        switch type.lowercased() {
        case "cf": return "⚡"
        case "icpc": return "🏅"
        case "ioi": return "🎯"
        default: return "🏆"
        }
    }
}

struct ConquestDurationBadge: View {
    let duration: Int
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text("⏱️")
                .font(.system(size: 12))
            Text(durationText)
                .font(.custom("TTPhobosTrial-Bold", size: 10))
                .foregroundColor(colorThemeManager.current.text.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorThemeManager.current.text.opacity(0.1))
        )
    }
    
    private var durationText: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Empty States and Loading
struct BattleLoadingView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(colorThemeManager.current.accent)
            
            Text("Scouting for battles...")
                .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
        )
    }
}

struct EmptyBattlesView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("⚔️")
                .font(.system(size: 60))
            
            VStack(spacing: 8) {
                Text("No Battles Scheduled")
                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text("The arena is quiet for now.\nCheck back later for new battles!")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
        )
    }
}

struct EmptyConquestsView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🏆")
                .font(.system(size: 60))
            
            VStack(spacing: 8) {
                Text("No Past Conquests")
                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text("The hall of legends awaits\nyour first victory!")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
        )
    }
}

// MARK: - Contest Status Badge
struct ContestStatusBadge: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            Text(contest.statusEmoji)
                .font(.system(size: 16))
            
            Text(contest.phaseDisplayText.uppercased())
                .font(.custom("TTPhobosTrial-Bold", size: 12))
                .foregroundColor(contest.phaseColorValue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(contest.phaseColorValue.opacity(0.1))
                .stroke(contest.phaseColorValue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Simple Live Contest Sheet (for upcoming/running contests)
struct LiveContestSheet: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Contest Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("⚔️")
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contest.name)
                                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                                    .foregroundColor(colorThemeManager.current.text)
                                    .lineLimit(3)
                                
                                ContestStatusBadge(contest: contest)
                            }
                            
                            Spacer()
                        }
                        
                        // Basic info
                        if let startDate = contest.startDate {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(colorThemeManager.current.accent)
                                Text(startDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                                    .foregroundColor(colorThemeManager.current.text)
                                
                                Spacer()
                                
                                Text("Duration: \(formatDuration(contest.durationSeconds))")
                                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            }
                        }
                        
                        if contest.isUpcoming, let timeUntilStart = contest.timeUntilStart {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.orange)
                                Text("Starts in: \(timeUntilStart)")
                                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorThemeManager.current.tabBar.opacity(0.6))
                    )
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        if contest.phase == "CODING" {
                            // Live contest - show join button
                            Button(action: {
                                if let url = URL(string: contest.contestUrl) {
                                    UIApplication.shared.open(url)
                                }
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bolt.circle.fill")
                                        .font(.system(size: 20, weight: .bold))
                                    
                                    Text("Join Live Contest")
                                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.green, Color.green.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        // Notification button
                        Button(action: {
                            scheduleContestNotifications()
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text("Set Smart Notifications")
                                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color.orange.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        if contest.isUpcoming {
                            // Registration button for upcoming contests
                            Button(action: {
                                if let url = URL(string: contest.registrationUrl) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.badge.plus.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    
                                    Text("Register for Contest")
                                        .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                                }
                                .foregroundColor(colorThemeManager.current.text)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(colorThemeManager.current.accent, lineWidth: 2)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Battle Ready")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorThemeManager.current.accent)
                }
            }
        }
    }
    
    private func scheduleContestNotifications() {
        guard let startDate = contest.startDate else { return }
        
        // 1 day before
        let oneDayBefore = startDate.addingTimeInterval(-24 * 60 * 60)
        if oneDayBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Contest Tomorrow! 📅",
                body: "\(contest.name) starts tomorrow",
                date: oneDayBefore,
                identifier: "contest_\(contest.id)_1day"
            )
        }
        
        // 1 hour before
        let oneHourBefore = startDate.addingTimeInterval(-60 * 60)
        if oneHourBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Contest Starting Soon! ⚔️",
                body: "\(contest.name) starts in 1 hour",
                date: oneHourBefore,
                identifier: "contest_\(contest.id)_1hour"
            )
        }
        
        // 15 minutes before
        let fifteenMinBefore = startDate.addingTimeInterval(-15 * 60)
        if fifteenMinBefore > Date() {
            NotificationManager.shared.scheduleNotification(
                title: "Final Call! 🔔",
                body: "\(contest.name) starts in 15 minutes!",
                date: fifteenMinBefore,
                identifier: "contest_\(contest.id)_15min"
            )
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Battle Details Sheet (for finished contests)
struct BattleDetailsSheet: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cfService = CFService.shared
    @State private var selectedTab: DetailTab = .overview
    @State private var contestProblems: [CFProblem] = []
    @State private var isLoadingProblems = false
    @State private var problemsError: String?
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case analytics = "Analytics"
        case actions = "Actions"
        
        var icon: String {
            switch self {
            case .overview: return "doc.text.fill"
            case .analytics: return "chart.bar.fill"
            case .actions: return "bolt.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    contestHeader
                    
                    // Tab Selector
                    tabSelector
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .overview:
                                overviewContent
                            case .analytics:
                                analyticsContent
                            case .actions:
                                actionsContent
                            }
                            
                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorThemeManager.current.accent)
                }
            }
            .onAppear {
                loadContestProblems()
            }
        }
    }
    
    // MARK: - Header
    private var contestHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("⚔️")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Battle Details")
                        .font(.custom("TTPhobosTrial-Bold", size: 24))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Text(contest.name)
                        .font(.custom("TTPhobosTrial-DemiBold", size: 18))
                        .foregroundColor(colorThemeManager.current.accent)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Status Badge
            HStack {
                ContestStatusBadge(contest: contest)
                
                if contest.isUpcoming, let timeUntilStart = contest.timeUntilStart {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text("Starts in \(timeUntilStart)")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    }
                    .foregroundColor(colorThemeManager.current.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorThemeManager.current.accent.opacity(0.1))
                    )
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(colorThemeManager.current.background)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(tab.rawValue)
                            .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    }
                    .foregroundColor(selectedTab == tab ? colorThemeManager.current.accent : colorThemeManager.current.text.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ? colorThemeManager.current.accent.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .background(colorThemeManager.current.background)
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Contest Status Card
            ContestInfoSection(
                title: "Battle Status",
                icon: "flag.checkered",
                color: contest.phaseColorValue
            ) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Phase")
                                .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            
                            HStack(spacing: 8) {
                                Text(contest.phaseDisplayText)
                                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                                    .foregroundColor(contest.phaseColorValue)
                                
                                Text(contest.statusEmoji)
                                    .font(.system(size: 18))
                            }
                        }
                        
                        Spacer()
                        
                        // Phase progress indicator
                        VStack(spacing: 4) {
                            Circle()
                                .fill(contest.phaseColorValue)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(contest.phaseColorValue.opacity(0.3), lineWidth: 8)
                                        .scaleEffect(1.5)
                                )
                            
                            Text("LIVE")
                                .font(.custom("TTPhobosTrial-Bold", size: 10))
                                .foregroundColor(contest.phaseColorValue)
                        }
                    }
                    
                    if contest.isUpcoming, let timeUntilStart = contest.timeUntilStart {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time Until Battle")
                                .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            
                            Text(timeUntilStart)
                                .font(.custom("TTPhobosTrial-Bold", size: 16))
                                .foregroundColor(colorThemeManager.current.accent)
                        }
                    }
                }
            }
            
            // Basic Info Card
            ContestInfoSection(
                title: "Battle Information",
                icon: "info.circle.fill",
                color: colorThemeManager.current.accent
            ) {
                VStack(spacing: 16) {
                    ContestDetailRow(
                        icon: "clock.fill",
                        title: "Start Time",
                        value: contest.startDate?.formatted(date: .complete, time: .shortened) ?? "TBA"
                    )
                    
                    ContestDetailRow(
                        icon: "timer",
                        title: "Duration",
                        value: formatDuration(contest.durationSeconds)
                    )
                    
                    ContestDetailRow(
                        icon: "flag.fill",
                        title: "Type",
                        value: contest.type.uppercased()
                    )
                    
                    ContestDetailRow(
                        icon: "gamecontroller.fill",
                        title: "Phase",
                        value: contest.phase.capitalized
                    )
                    
                    if let difficulty = contest.difficulty {
                        ContestDetailRow(
                            icon: "target",
                            title: "Difficulty",
                            value: "Level \(difficulty)"
                        )
                    }
                    
                    if let country = contest.country {
                        ContestDetailRow(
                            icon: "globe",
                            title: "Region",
                            value: country
                        )
                    }
                    
                    if let preparedBy = contest.preparedBy {
                        ContestDetailRow(
                            icon: "person.crop.circle.fill",
                            title: "Prepared By",
                            value: preparedBy
                        )
                    }
                }
            }
            
            // Quick Stats Grid
            ContestInfoSection(
                title: "Quick Stats",
                icon: "chart.bar.doc.horizontal.fill",
                color: .blue
            ) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    QuickStatCard(
                        title: "Contest ID",
                        value: "#\(contest.id)",
                        icon: "number.circle.fill",
                        color: .blue
                    )
                    
                    QuickStatCard(
                        title: "Rating Impact",
                        value: contest.phase == "FINISHED" ? "Rated" : "TBD",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    QuickStatCard(
                        title: "Duration",
                        value: "\(contest.durationSeconds / 3600)h",
                        icon: "clock.fill",
                        color: .orange
                    )
                    
                    QuickStatCard(
                        title: "Type",
                        value: contest.type.uppercased(),
                        icon: "tag.fill",
                        color: .green
                    )
                }
            }
            
            // Contest Problems Section (for finished and running contests)
            if contest.isFinished || contest.isRunning {
                ContestInfoSection(
                    title: contest.isFinished ? "Problem Set" : "Live Problems",
                    icon: contest.isFinished ? "list.bullet.rectangle.fill" : "bolt.circle.fill",
                    color: contest.isFinished ? .indigo : .orange
                ) {
                    ContestProblemsView(
                        problems: contestProblems,
                        isLoading: isLoadingProblems,
                        contest: contest
                    )
                }
            }
            
            // Description Card (if available)
            if let description = contest.description, !description.isEmpty {
                ContestInfoSection(
                    title: "Description",
                    icon: "doc.text.fill",
                    color: .purple
                ) {
                    Text(description)
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 8)
                }
            }
            
            // Contest Links Section
            ContestInfoSection(
                title: "Quick Access",
                icon: "link.circle.fill",
                color: .cyan
            ) {
                VStack(spacing: 12) {
                    QuickLinkRow(
                        title: "Contest Portal",
                        icon: "globe",
                        url: contest.contestUrl,
                        color: colorThemeManager.current.accent
                    )
                    
                    if contest.isUpcoming {
                        QuickLinkRow(
                            title: "Registration",
                            icon: "person.badge.plus.fill",
                            url: contest.registrationUrl,
                            color: .green
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Analytics Content
    private var analyticsContent: some View {
        VStack(spacing: 20) {
            // Contest Performance Metrics
            ContestInfoSection(
                title: "Contest Metrics",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            ) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    MetricCard(
                        title: "Contest ID",
                        value: "#\(contest.id)",
                        subtitle: "Unique identifier",
                        icon: "number.circle.fill",
                        color: .blue
                    )
                    
                    MetricCard(
                        title: "Est. Problems",
                        value: "\(contest.estimatedProblems)",
                        subtitle: "Expected count",
                        icon: "list.number",
                        color: .green
                    )
                    
                    MetricCard(
                        title: "Difficulty",
                        value: contest.difficultyText,
                        subtitle: contest.difficulty != nil ? "Level \(contest.difficulty!)" : "Not rated",
                        icon: "target",
                        color: .red
                    )
                    
                    MetricCard(
                        title: "Rating Impact",
                        value: contest.ratingImpact,
                        subtitle: "Performance affects rating",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
            }
            
            // Time Analytics
            ContestInfoSection(
                title: "Time Analysis",
                icon: "clock.fill",
                color: .purple
            ) {
                VStack(spacing: 16) {
                    if let startDate = contest.startDate {
                        TimeAnalysisRow(
                            title: "Start Date",
                            value: startDate.formatted(date: .complete, time: .omitted),
                            subtitle: startDate.formatted(date: .omitted, time: .complete)
                        )
                        
                        if let endDate = contest.endDate {
                            TimeAnalysisRow(
                                title: "End Date",
                                value: endDate.formatted(date: .complete, time: .omitted),
                                subtitle: endDate.formatted(date: .omitted, time: .complete)
                            )
                        }
                        
                        // Day of week analysis
                        let dayOfWeek = Calendar.current.component(.weekday, from: startDate)
                        let dayName = DateFormatter().weekdaySymbols[dayOfWeek - 1]
                        TimeAnalysisRow(
                            title: "Day of Week",
                            value: dayName,
                            subtitle: "Contest scheduling pattern"
                        )
                    }
                    
                    TimeAnalysisRow(
                        title: "Duration",
                        value: formatDuration(contest.durationSeconds),
                        subtitle: "\(contest.durationSeconds / 60) minutes total"
                    )
                    
                    // Time per problem estimation
                    let timePerProblem = contest.durationSeconds / contest.estimatedProblems / 60
                    TimeAnalysisRow(
                        title: "Avg. Time/Problem",
                        value: "\(timePerProblem) minutes",
                        subtitle: "Strategic time allocation"
                    )
                    
                    if contest.isUpcoming, let timeUntilStart = contest.timeUntilStart {
                        TimeAnalysisRow(
                            title: "Time Until Start",
                            value: timeUntilStart,
                            subtitle: "Battle preparation time"
                        )
                    }
                }
            }
            
            // Contest Insights
            ContestInfoSection(
                title: "Strategic Insights",
                icon: "brain.head.profile",
                color: .cyan
            ) {
                VStack(spacing: 16) {
                    InsightCard(
                        title: "Contest Format",
                        description: getContestFormatInsight(),
                        icon: "gamecontroller.fill",
                        color: .blue
                    )
                    
                    InsightCard(
                        title: "Preparation Tips",
                        description: getPreparationTips(),
                        icon: "lightbulb.fill",
                        color: .yellow
                    )
                    
                    InsightCard(
                        title: "Time Strategy",
                        description: getTimeStrategy(),
                        icon: "clock.arrow.circlepath",
                        color: .green
                    )
                    
                    if contest.isUpcoming {
                        InsightCard(
                            title: "Last-Minute Prep",
                            description: getLastMinutePrep(),
                            icon: "bolt.fill",
                            color: .orange
                        )
                    }
                }
            }
            
            // Historical Context
            ContestInfoSection(
                title: "Historical Context",
                icon: "chart.bar.doc.horizontal",
                color: .indigo
            ) {
                VStack(spacing: 16) {
                    HistoricalStatRow(
                        title: "Contest Series",
                        value: contest.typeDisplayText,
                        description: "Part of regular contest series"
                    )
                    
                    if let country = contest.country {
                        HistoricalStatRow(
                            title: "Regional Focus",
                            value: country,
                            description: "Contest targeting specific region"
                        )
                    }
                    
                    if let season = contest.season {
                        HistoricalStatRow(
                            title: "Season",
                            value: season,
                            description: "Part of competitive programming season"
                        )
                    }
                    
                    HistoricalStatRow(
                        title: "Participation",
                        value: "Global",
                        description: "Open to worldwide participants"
                    )
                }
            }
        }
    }
    
    private func getContestFormatInsight() -> String {
        switch contest.type.lowercased() {
        case "cf":
            return "Standard Codeforces format with \(contest.estimatedProblems) problems. Focus on speed and accuracy."
        case "ioi":
            return "IOI-style contest with 3 challenging problems. Partial scoring available."
        case "icpc":
            return "ICPC format emphasizing teamwork and problem-solving strategy."
        default:
            return "Contest format: \(contest.type). Check rules for specific details."
        }
    }
    
    private func getPreparationTips() -> String {
        let hours = contest.durationSeconds / 3600
        if hours <= 2 {
            return "Short contest - practice speed coding and quick problem analysis."
        } else if hours <= 3 {
            return "Standard duration - balance speed with thorough problem understanding."
        } else {
            return "Extended contest - focus on endurance and complex problem solving."
        }
    }
    
    private func getTimeStrategy() -> String {
        let timePerProblem = contest.durationSeconds / contest.estimatedProblems / 60
        if timePerProblem < 20 {
            return "Fast-paced: \(timePerProblem)min/problem. Quick implementation crucial."
        } else if timePerProblem < 40 {
            return "Balanced: \(timePerProblem)min/problem. Time for debugging and optimization."
        } else {
            return "Deep thinking: \(timePerProblem)min/problem. Complex algorithms expected."
        }
    }
    
    private func getLastMinutePrep() -> String {
        guard let startDate = contest.startDate else { return "Prepare your coding environment and review key algorithms." }
        let timeUntil = startDate.timeIntervalSinceNow
        
        if timeUntil < 3600 { // Less than 1 hour
            return "Final preparations: Check internet, test IDE, and stay calm."
        } else if timeUntil < 86400 { // Less than 1 day
            return "Review key algorithms, practice similar problems, prepare snacks."
        } else {
            return "Plan your schedule, review contest format, practice regularly."
        }
    }
    
    // MARK: - Actions Content
    private var actionsContent: some View {
        VStack(spacing: 20) {
            // Quick Actions
            ContestInfoSection(
                title: "Battle Actions",
                icon: "bolt.fill",
                color: .yellow
            ) {
                VStack(spacing: 16) {
                    ActionRow(
                        title: "Enter Contest",
                        subtitle: "Access contest problems and submit solutions",
                        icon: "sword.fill",
                        color: colorThemeManager.current.accent,
                        url: contest.contestUrl
                    )
                    
                    if contest.isUpcoming {
                        ActionRow(
                            title: "Register",
                            subtitle: "Register for the upcoming contest",
                            icon: "person.badge.plus.fill",
                            color: .green,
                            url: contest.registrationUrl
                        )
                    }
                    
                    ActionRow(
                        title: "Announcements",
                        subtitle: "Read contest announcements and updates",
                        icon: "megaphone.fill",
                        color: .purple,
                        url: contest.announcementsUrl
                    )
                }
            }
            
            // Strategic Actions
            ContestInfoSection(
                title: "Battle Strategy",
                icon: "brain.head.profile.fill",
                color: .cyan
            ) {
                VStack(spacing: 16) {
                    StrategyActionRow(
                        title: "Details & Analysis",
                        subtitle: "Get detailed contest insights and tips",
                        icon: "info.circle.fill",
                        color: .cyan
                    ) {
                        // Add AI analysis action
                    }
                    
                    StrategyActionRow(
                        title: "Practice Mode",
                        subtitle: "Review similar problems for preparation",
                        icon: "dumbbell.fill",
                        color: .green
                    ) {
                        // Add practice mode action
                    }
                    
                    StrategyActionRow(
                        title: "Study Contest",
                        subtitle: "Add to your study list for later review",
                        icon: "bookmark.fill",
                        color: .yellow
                    ) {
                        // Add bookmark action
                    }
                    
                    StrategyActionRow(
                        title: "Team Invite",
                        subtitle: "Share contest with your coding team",
                        icon: "person.3.fill",
                        color: .blue
                    ) {
                        // Add team sharing action
                    }
                }
            }
            
            // Notification Actions
            ContestInfoSection(
                title: "Notifications",
                icon: "bell.fill",
                color: .red
            ) {
                VStack(spacing: 16) {
                    NotificationActionRow(
                        title: "Set Reminder",
                        subtitle: "Get notified before contest starts",
                        icon: "bell.badge.fill"
                    ) {
                        NotificationManager.shared.scheduleNotification(
                            title: "Contest Reminder",
                            body: "\(contest.name) is starting soon!",
                            date: contest.startDate ?? Date(),
                            identifier: "contest_\(contest.id)"
                        )
                    }
                    
                    NotificationActionRow(
                        title: "Multiple Reminders",
                        subtitle: "Set reminders 1 day, 1 hour, and 15 min before",
                        icon: "alarm.fill"
                    ) {
                        setMultipleReminders()
                    }
                    
                    if #available(iOS 16.1, *) {
                        NotificationActionRow(
                            title: "Live Activity",
                            subtitle: "Track contest progress in real-time",
                            icon: "waveform.path.ecg.rectangle.fill"
                        ) {
                            #if canImport(ActivityKit)
                            NotificationManager.shared.startContestLiveActivity(contest: contest)
                            #endif
                        }
                    }
                }
            }
            
            // Contest Preparation
            ContestInfoSection(
                title: "Preparation Tools",
                icon: "hammer.fill",
                color: .indigo
            ) {
                VStack(spacing: 16) {
                    PreparationActionRow(
                        title: "Past Problems",
                        subtitle: "Review similar contest problems",
                        icon: "clock.arrow.circlepath",
                        color: .purple
                    ) {
                        // Add past problems action
                    }
                    
                    PreparationActionRow(
                        title: "Difficulty Analysis",
                        subtitle: "Analyze expected problem difficulty range",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    ) {
                        // Add difficulty analysis action
                    }
                    
                    PreparationActionRow(
                        title: "Time Strategy",
                        subtitle: "Calculate optimal time allocation per problem",
                        icon: "stopwatch.fill",
                        color: .green
                    ) {
                        // Add time strategy action
                    }
                    
                    PreparationActionRow(
                        title: "Editorial Access",
                        subtitle: "Quick access to solutions after contest",
                        icon: "doc.text.magnifyingglass",
                        color: .blue
                    ) {
                        // Add editorial access action
                    }
                }
            }
        }
    }
    
    private func setMultipleReminders() {
        guard let startDate = contest.startDate else { return }
        
        // 1 day before
        let oneDayBefore = startDate.addingTimeInterval(-24 * 60 * 60)
        NotificationManager.shared.scheduleNotification(
            title: "Contest Tomorrow",
            body: "\(contest.name) starts tomorrow at \(startDate.formatted(date: .omitted, time: .shortened))",
            date: oneDayBefore,
            identifier: "contest_\(contest.id)_1day"
        )
        
        // 1 hour before
        let oneHourBefore = startDate.addingTimeInterval(-60 * 60)
        NotificationManager.shared.scheduleNotification(
            title: "Contest Starting Soon",
            body: "\(contest.name) starts in 1 hour!",
            date: oneHourBefore,
            identifier: "contest_\(contest.id)_1hour"
        )
        
        // 15 minutes before
        let fifteenMinBefore = startDate.addingTimeInterval(-15 * 60)
        NotificationManager.shared.scheduleNotification(
            title: "Contest Alert",
            body: "\(contest.name) starts in 15 minutes! Get ready!",
            date: fifteenMinBefore,
            identifier: "contest_\(contest.id)_15min"
        )
    }
    
    private func loadContestProblems() {
        guard contest.isFinished || contest.isRunning else { return }
        
        isLoadingProblems = true
        Task {
            let problems = await cfService.fetchContestProblems(contestId: contest.id)
            await MainActor.run {
                self.contestProblems = problems
                self.isLoadingProblems = false
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours) hours \(minutes) minutes"
        } else if hours > 0 {
            return "\(hours) hours"
        } else {
            return "\(minutes) minutes"
        }
    }
}

// MARK: - Contest Problems View
struct ContestProblemsView: View {
    let problems: [CFProblem]
    let isLoading: Bool
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var difficultyDistribution: [(color: Color, count: Int)] {
        let ratingGroups = Dictionary(grouping: problems.compactMap { $0.rating }) { rating in
            switch rating {
            case 0..<1200: return 0
            case 1200..<1600: return 1
            case 1600..<1900: return 2
            case 1900..<2100: return 3
            case 2100..<2400: return 4
            default: return 5
            }
        }
        
        let colors: [Color] = [.green, .cyan, .blue, .purple, .orange, .red]
        return ratingGroups.sorted(by: { $0.key < $1.key }).map { (color: colors[$0.key], count: $0.value.count) }
    }
    
    private var topTags: [String] {
        let allTags = problems.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(tagCounts.prefix(5).map { $0.key })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading problems...")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
                .frame(height: 60)
            } else if problems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.questionmark.fill")
                        .font(.system(size: 24))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.4))
                    
                    Text("No problems available")
                        .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    
                    Text("Problem data may not be accessible")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.4))
                }
                .frame(height: 80)
            } else {
                VStack(spacing: 16) {
                    // Header with problem count and stats
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(problems.count) Problem\(problems.count == 1 ? "" : "s")")
                                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                                    .foregroundColor(colorThemeManager.current.text)
                                
                                Text("Contest #\(contest.id)")
                                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            // Difficulty distribution
                            if !problems.isEmpty {
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 8) {
                                        ForEach(difficultyDistribution, id: \.color) { diff in
                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(diff.color)
                                                    .frame(width: 8, height: 8)
                                                Text("\(diff.count)")
                                                    .font(.custom("TTPhobosTrial-Bold", size: 10))
                                                    .foregroundColor(diff.color)
                                            }
                                        }
                                    }
                                    
                                    Text("Difficulty spread")
                                        .font(.custom("TTPhobosTrial-Regular", size: 10))
                                        .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                                }
                            }
                        }
                        
                        // Problem type tags summary
                        if !topTags.isEmpty {
                            HStack {
                                Text("Common tags:")
                                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(topTags.prefix(4), id: \.self) { tag in
                                            Text(tag)
                                                .font(.custom("TTPhobosTrial-Regular", size: 11))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(colorThemeManager.current.accent.opacity(0.1))
                                                )
                                                .foregroundColor(colorThemeManager.current.accent)
                                        }
                                    }
                                    .padding(.horizontal, 1)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Problems list
                    ForEach(Array(problems.enumerated()), id: \.element.id) { index, problem in
                        ProblemRow(
                            problem: problem,
                            index: index,
                            contestId: contest.id
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Problem Row
struct ProblemRow: View {
    let problem: CFProblem
    let index: Int
    let contestId: Int
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var difficultyColor: Color {
        guard let rating = problem.rating else { return .gray }
        switch rating {
        case 0..<1200: return .green
        case 1200..<1600: return .cyan
        case 1600..<1900: return .blue
        case 1900..<2100: return .purple
        case 2100..<2400: return .orange
        default: return .red
        }
    }
    
    private var problemUrl: String {
        "https://codeforces.com/contest/\(contestId)/problem/\(problem.index)"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Problem index with enhanced visual
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(difficultyColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(difficultyColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(problem.index)
                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                        .foregroundColor(difficultyColor)
                }
                
                // Problem type indicator
                if let points = problem.points, points > 0 {
                    Text("\(Int(points))pt")
                        .font(.custom("TTPhobosTrial-Regular", size: 9))
                        .foregroundColor(difficultyColor)
                        .opacity(0.8)
                } else if let rating = problem.rating {
                    Text("\(rating)")
                        .font(.custom("TTPhobosTrial-Regular", size: 9))
                        .foregroundColor(difficultyColor)
                        .opacity(0.8)
                }
            }
            
            // Problem details with better layout
            VStack(alignment: .leading, spacing: 6) {
                Text(problem.name)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 15))
                    .foregroundColor(colorThemeManager.current.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Rating and difficulty info
                HStack(spacing: 12) {
                    if let rating = problem.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(difficultyColor)
                            
                            Text("\(rating)")
                                .font(.custom("TTPhobosTrial-Bold", size: 12))
                                .foregroundColor(difficultyColor)
                            
                            Text("• \(difficultyText)")
                                .font(.custom("TTPhobosTrial-Regular", size: 11))
                                .foregroundColor(difficultyColor.opacity(0.8))
                        }
                    }
                }
                
                // Tags with better styling
                if !problem.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(problem.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.custom("TTPhobosTrial-Regular", size: 10))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(colorThemeManager.current.text.opacity(0.08))
                                    )
                                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Enhanced action button
            VStack(spacing: 8) {
                Button(action: {
                    if let url = URL(string: problemUrl) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorThemeManager.current.accent)
                        
                        Text("View")
                            .font(.custom("TTPhobosTrial-Bold", size: 9))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorThemeManager.current.tabBar.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(difficultyColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var difficultyText: String {
        guard let rating = problem.rating else { return "Unrated" }
        switch rating {
        case 0..<1200: return "Beginner"
        case 1200..<1600: return "Easy"
        case 1600..<1900: return "Medium"
        case 1900..<2100: return "Hard"
        case 2100..<2400: return "Expert"
        default: return "Master"
        }
    }
}


struct ContestDetailRow: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(colorThemeManager.current.accent)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                
                Text(value)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Enhanced Supporting Components
struct ContestInfoSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(title)
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.6))
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let url: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        if let validUrl = URL(string: url) {
            Link(destination: validUrl) {
                actionContent
            }
            .buttonStyle(.plain)
        } else {
            actionContent
                .opacity(0.5)
        }
    }
    
    private var actionContent: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(colorThemeManager.current.text.opacity(0.4))
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct StrategyActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Text(subtitle)
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(colorThemeManager.current.text.opacity(0.4))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PreparationActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.custom("TTPhobosTrial-Bold", size: 16))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text("PRO")
                            .font(.custom("TTPhobosTrial-Bold", size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color)
                            )
                    }
                    
                    Text(subtitle)
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(colorThemeManager.current.text.opacity(0.4))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct NotificationActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var isEnabled = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .red))
                .onChange(of: isEnabled) { _, newValue in
                    if newValue {
                        action()
                    }
                }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24, weight: .semibold))
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TimeAnalysisRow: View {
    let title: String
    let value: String
    let subtitle: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                
                Text(value)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18, weight: .semibold))
            
            Text(value)
                .font(.custom("TTPhobosTrial-Bold", size: 16))
                .foregroundColor(colorThemeManager.current.text)
            
            Text(title)
                .font(.custom("TTPhobosTrial-DemiBold", size: 11))
                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.08))
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct QuickLinkRow: View {
    let title: String
    let icon: String
    let url: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        if let validUrl = URL(string: url) {
            Link(destination: validUrl) {
                linkContent
            }
            .buttonStyle(.plain)
        } else {
            linkContent
                .opacity(0.5)
        }
    }
    
    private var linkContent: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20)
            
            Text(title)
                .font(.custom("TTPhobosTrial-DemiBold", size: 15))
                .foregroundColor(colorThemeManager.current.text)
            
            Spacer()
            
            Image(systemName: "arrow.up.right")
                .foregroundColor(colorThemeManager.current.text.opacity(0.4))
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20, weight: .semibold))
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 10))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

struct InsightCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(description)
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

struct HistoricalStatRow: View {
    let title: String
    let value: String
    let description: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                
                Text(value)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(description)
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Battle Analysis Sheet
struct BattleAnalysisSheet: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cfService = CFService.shared
    @StateObject private var geminiService = GeminiService.shared
    @State private var selectedTab = 0
    @State private var contestProblems: [CFProblem] = []
    @State private var isLoadingProblems = false
    @State private var problemsError: String?
    @State private var aiAnalysis: String?
    @State private var isLoadingAnalysis = false
    @State private var analysisError: String?
    
    private let tabs = ["📊 Overview", "🧩 Problems", "🧠 Details"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Contest Header
                    VStack(spacing: 16) {
                        Text("🏆")
                            .font(.system(size: 40))
                        
                        Text(contest.name)
                            .font(.custom("TTPhobosTrial-Bold", size: 22))
                            .foregroundColor(colorThemeManager.current.text)
                            .multilineTextAlignment(.center)
                        
                        Text("CONQUEST COMPLETED")
                            .font(.custom("TTPhobosTrial-Bold", size: 12))
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                            )
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    // Custom Tab Selector
                    HStack(spacing: 0) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = index
                                }
                            }) {
                                Text(tabs[index])
                                    .font(.custom("TTPhobosTrial-Bold", size: 14))
                                    .foregroundColor(selectedTab == index ? colorThemeManager.current.text : colorThemeManager.current.text.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(selectedTab == index ? colorThemeManager.current.accent.opacity(0.1) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        // Overview Tab
                        OverviewTabContent()
                            .tag(0)
                        
                        // Problems Tab
                        ProblemsTabContent()
                            .tag(1)
                        
                        // Details Tab
                        DetailsTabContent()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Battle Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorThemeManager.current.accent)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                }
            }
        }
        .task {
            await loadContestProblems()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 2 && aiAnalysis == nil && !isLoadingAnalysis {
                Task {
                    await generateAIAnalysis()
                }
            }
        }
    }
    
    @ViewBuilder
    private func OverviewTabContent() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Contest Info Cards
                VStack(spacing: 16) {
                    if let startDate = contest.startDate {
                        InfoRow(title: "Completed", value: startDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    
                    InfoRow(title: "Duration", value: formatDuration(contest.durationSeconds))
                    InfoRow(title: "Type", value: contest.type)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorThemeManager.current.tabBar.opacity(0.8))
                )
                
                // Quick Actions
                VStack(spacing: 12) {
                    Text("⚡ Quick Actions")
                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                        .foregroundColor(colorThemeManager.current.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "View Contest",
                            icon: "doc.text.fill",
                            color: colorThemeManager.current.accent,
                            action: {
                                if let url = URL(string: contest.contestUrl) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                        
                        ActionButton(
                            title: "Details",
                            icon: "info.circle.fill",
                            color: .blue,
                            action: {
                                // Additional details action if needed
                            }
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorThemeManager.current.tabBar.opacity(0.8))
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    @ViewBuilder
    private func ProblemsTabContent() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoadingProblems {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading contest problems...")
                            .font(.custom("TTPhobosTrial-Regular", size: 16))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    .padding(.top, 50)
                } else if let error = problemsError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Unable to load problems")
                            .font(.custom("TTPhobosTrial-Bold", size: 18))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text(error)
                            .font(.custom("TTPhobosTrial-Regular", size: 14))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await loadContestProblems()
                            }
                        }
                        .foregroundColor(colorThemeManager.current.accent)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                    }
                    .padding(.top, 50)
                } else if contestProblems.isEmpty {
                    VStack(spacing: 16) {
                        Text("🧩")
                            .font(.system(size: 40))
                        
                        Text("No problems available")
                            .font(.custom("TTPhobosTrial-Bold", size: 18))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text("Contest problems couldn't be retrieved")
                            .font(.custom("TTPhobosTrial-Regular", size: 14))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    .padding(.top, 50)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(contestProblems, id: \.id) { problem in
                            ProblemRow(problem: problem, index: 0, contestId: contest.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    @ViewBuilder
    private func DetailsTabContent() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoadingAnalysis {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Generating analysis...")
                            .font(.custom("TTPhobosTrial-Regular", size: 16))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    .padding(.top, 50)
                } else if let error = analysisError {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Analysis Failed")
                            .font(.custom("TTPhobosTrial-Bold", size: 18))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text(error)
                            .font(.custom("TTPhobosTrial-Regular", size: 14))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                            .multilineTextAlignment(.center)
                        
                        Button("Retry Analysis") {
                            Task {
                                await generateAIAnalysis()
                            }
                        }
                        .foregroundColor(colorThemeManager.current.accent)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                    }
                    .padding(.top, 50)
                } else if let analysis = aiAnalysis {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("🧠")
                                .font(.system(size: 24))
                            
                            Text("Analysis")
                                .font(.custom("TTPhobosTrial-Bold", size: 20))
                                .foregroundColor(colorThemeManager.current.text)
                        }
                        
                        Text(analysis)
                            .font(.custom("TTPhobosTrial-Regular", size: 16))
                            .foregroundColor(colorThemeManager.current.text)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(colorThemeManager.current.tabBar.opacity(0.8))
                    )
                } else {
                    VStack(spacing: 16) {
                        Text("🧠")
                            .font(.system(size: 40))
                        
                        Text("Analysis Ready")
                            .font(.custom("TTPhobosTrial-Bold", size: 18))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Button("Generate Analysis") {
                            Task {
                                await generateAIAnalysis()
                            }
                        }
                        .foregroundColor(.white)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorThemeManager.current.accent)
                        )
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    private func loadContestProblems() async {
        isLoadingProblems = true
        problemsError = nil
        
        do {
            let problems = try await cfService.fetchContestProblems(contestId: contest.id)
            await MainActor.run {
                self.contestProblems = problems
                self.isLoadingProblems = false
            }
        } catch {
            await MainActor.run {
                self.problemsError = error.localizedDescription
                self.isLoadingProblems = false
            }
        }
    }
    
    private func generateAIAnalysis() async {
        isLoadingAnalysis = true
        analysisError = nil
        
        let contestData = """
        Contest: \(contest.name)
        Type: \(contest.type)
        Duration: \(formatDuration(contest.durationSeconds))
        Problems: \(contestProblems.count) problems
        \(contestProblems.map { "- \($0.name) (Rating: \($0.rating ?? 0))" }.joined(separator: "\n"))
        """
        
        do {
            let analysis = try await geminiService.analyzeContest(contestData: contestData)
            await MainActor.run {
                self.aiAnalysis = analysis
                self.isLoadingAnalysis = false
            }
        } catch {
            await MainActor.run {
                self.analysisError = error.localizedDescription
                self.isLoadingAnalysis = false
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}



#Preview {
    ContestListView()
        .environmentObject(ColorThemeManager())
}
