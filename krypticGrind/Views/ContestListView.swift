//
//  ContestListView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
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
    @State private var showingDetails = false
    @State private var showLiveActivityError = false
    
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
                ActionButton(
                    title: "Register",
                    icon: "arrow.right.circle.fill",
                    color: colorThemeManager.current.accent
                ) {
                    if let url = URL(string: "https://codeforces.com/contest/\(contest.id)/register") {
                        UIApplication.shared.open(url)
                    }
                }
                
                ActionButton(
                    title: "Notify",
                    icon: "bell.fill",
                    color: Color.orange
                ) {
                    NotificationManager.shared.scheduleNotification(
                        title: "Contest Reminder",
                        body: "\(contest.name) is starting soon!",
                        date: contest.startDate ?? Date(),
                        identifier: "contest_\(contest.id)"
                    )
                }
                
                if isLiveActivitySupported {
                    ActionButton(
                        title: "Live",
                        icon: "waveform.path.ecg.rectangle",
                        color: .green
                    ) {
                        #if canImport(ActivityKit)
                        NotificationManager.shared.startContestLiveActivity(contest: contest)
                        #endif
                    }
                } else {
                    ActionButton(
                        title: "Live",
                        icon: "waveform.path.ecg.rectangle",
                        color: .gray.opacity(0.5)
                    ) {
                        showLiveActivityError = true
                    }
                    .disabled(true)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
        .alert("Live Activity Not Supported", isPresented: $showLiveActivityError) {
            Button("OK") { }
        } message: {
            Text("Live Activities require iOS 16.1 or later.")
        }
    }
    
    private var isLiveActivitySupported: Bool {
        if #available(iOS 16.1, *) {
            return ActivityKit.ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
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
    @State private var showingDetails = false
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
                Button(action: {
                    showingDetails = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                        Text("Details")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    }
                    .foregroundColor(colorThemeManager.current.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorThemeManager.current.tabBar.opacity(0.6))
                    )
                }
                
                if let url = URL(string: contest.contestUrl) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "sword.fill")
                                .font(.system(size: 14))
                            Text("Enter Battle")
                                .font(.custom("TTPhobosTrial-Bold", size: 14))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorThemeManager.current.accent)
                        )
                    }
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
        .sheet(isPresented: $showingDetails) {
            BattleDetailsSheet(contest: contest)
        }
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
            
            // Action button
            HStack {
                if let url = URL(string: contest.contestUrl) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "scroll.fill")
                                .font(.system(size: 14))
                            Text("View Results")
                                .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        }
                        .foregroundColor(colorThemeManager.current.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorThemeManager.current.tabBar.opacity(0.6))
                        )
                    }
                }
                
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

// MARK: - Battle Details Sheet
struct BattleDetailsSheet: View {
    let contest: CFContest
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Battle Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("⚔️")
                                .font(.system(size: 24))
                            
                            Text("Battle Details")
                                .font(.custom("TTPhobosTrial-Bold", size: 24))
                                .foregroundColor(colorThemeManager.current.text)
                            
                            Spacer()
                        }
                        
                        Text(contest.name)
                            .font(.custom("TTPhobosTrial-Bold", size: 20))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                    
                    Divider()
                        .background(colorThemeManager.current.text.opacity(0.2))
                    
                    // Battle Info
                    VStack(alignment: .leading, spacing: 16) {
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
                        
                        // Participant count not available in API
                        
                        if let country = contest.country {
                            ContestDetailRow(
                                icon: "globe",
                                title: "Region",
                                value: country
                            )
                        }
                    }
                    
                    // Action Button
                    if let url = URL(string: contest.contestUrl) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "sword.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Enter the Arena")
                                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorThemeManager.current.accent)
                            )
                        }
                        .padding(.top, 20)
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(20)
            }
            .background(colorThemeManager.current.background)
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

#Preview {
    ContestListView()
        .environmentObject(ColorThemeManager())
}
