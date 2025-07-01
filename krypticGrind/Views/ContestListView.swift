//
//  ContestListView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct ContestListView: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingFinishedContests = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toggle between upcoming and finished
                ContestToggle(showingFinished: $showingFinishedContests)
                    .padding()
                
                if showingFinishedContests {
                    FinishedContestsList()
                } else {
                    UpcomingContestsList()
                }
            }
            .background(themeManager.colors.background)
            .navigationTitle("Contests")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Test Notification", systemImage: "bell") {
                            NotificationManager.shared.testNotification()
                        }
                        Button("Test Live Activity", systemImage: "waveform.path.ecg.rectangle") {
                            NotificationManager.shared.testLiveActivity()
                        }
                    } label: {
                        Image(systemName: "bell")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Test Actions")
                }
            }
        }
        .task {
            await cfService.fetchContests()
        }
        .refreshable {
            await cfService.fetchContests()
        }
    }
}

struct ContestToggle: View {
    @Binding var showingFinished: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                showingFinished = false
            }) {
                Text("Upcoming")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(showingFinished ? Color.secondary : Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(showingFinished ? Color.clear : themeManager.colors.accent, in: .rect(topLeadingRadius: 8, bottomLeadingRadius: 8))
            }
            
            Button(action: {
                showingFinished = true
            }) {
                Text("Recent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(showingFinished ? Color.white : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(showingFinished ? themeManager.colors.accent : Color.clear, in: .rect(bottomTrailingRadius: 8, topTrailingRadius: 8))
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingFinished)
    }
}

struct UpcomingContestsList: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
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
                    .padding()
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
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding()
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
            .padding()
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
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingDetails = false
    @State private var showLiveActivityError = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
            VStack(alignment: .leading, spacing: 0) {
                // Top: Category chips
                HStack(spacing: 8) {
                    Chip(text: contest.type.capitalized, color: .blue)
                    if let country = contest.country {
                        Chip(text: country, color: .gray)
                    }
                    Chip(text: contest.phaseDisplayText, color: contest.phaseColorValue)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                // Main info
                HStack(alignment: .top, spacing: 16) {
                    // Placeholder image
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemGray5))
                            .frame(width: 72, height: 72)
                        Image(systemName: "trophy.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(contest.name)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        if let startDate = contest.startDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                Text(startDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let timeUntil = contest.timeUntilStart {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                Text(timeUntil)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                // Info blocks
                HStack(spacing: 16) {
                    InfoBlock(icon: "timer", text: contest.duration)
                    InfoBlock(icon: "person.3", text: contest.type.capitalized)
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
                // Action buttons
                HStack(spacing: 12) {
                    ActionButton(title: "Register", icon: "arrow.right.circle.fill", color: .blue) {
                        if let url = URL(string: "https://codeforces.com/contest/\(contest.id)/register") {
                            UIApplication.shared.open(url)
                        }
                    }
                    ActionButton(title: "Notify", icon: "bell.fill", color: .orange) {
                        NotificationManager.shared.scheduleNotification(
                            title: "Contest Reminder",
                            body: "\(contest.name) is starting soon!",
                            date: contest.startDate ?? Date(),
                            identifier: "contest_\(contest.id)"
                        )
                    }
                    if isLiveActivitySupported {
                        ActionButton(title: "Live", icon: "waveform.path.ecg.rectangle", color: .green) {
                            #if canImport(ActivityKit)
                            NotificationManager.shared.startContestLiveActivity(contest: contest)
                            #endif
                        }
                    } else {
                        ActionButton(title: "Live", icon: "waveform.path.ecg.rectangle", color: .gray.opacity(0.5)) {
                            showLiveActivityError = true
                        }
                        .disabled(true)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, 4)
        .alert(isPresented: $showLiveActivityError) {
            Alert(title: Text("Live Activities Not Supported"), message: Text("Live Activities are not supported on this device or iOS version."), dismissButton: .default(Text("OK")))
        }
    }
    var isLiveActivitySupported: Bool {
        if #available(iOS 16.1, *), ProcessInfo.processInfo.isiOSAppOnMac == false {
            return true
        }
        return false
    }
}

// Helper UI components
struct Chip: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

struct InfoBlock: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(8)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
        }
    }
}

struct ContestInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
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
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct FinishedContestCard: View {
    let contest: CFContest
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contest.name)
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    if let startDate = contest.startDate {
                        Text("Held on \(startDate.formatted())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text("Finished")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .foregroundStyle(.secondary)
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
                        .foregroundStyle(themeManager.colors.accent)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ContestInfoItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }
        }
    }
}

struct EmptyContestsView: View {
    let isUpcoming: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isUpcoming ? "calendar" : "checkmark.circle")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)
            
            Text(isUpcoming ? "No upcoming contests" : "Loading recent contests...")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            Text(isUpcoming ? 
                 "Check back later for new contests" : 
                 "Please wait while we fetch contest data"
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ContestDetailSheet: View {
    let contest: CFContest
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Contest Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text(contest.name)
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            
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
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Contest Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                            
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
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Description
                        if let description = contest.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.headline.bold())
                                    .foregroundStyle(.primary)
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Action Button
                        Button(action: {
                            if let url = URL(string: contest.contestUrl) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Open in Codeforces", systemImage: "link")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.colors.accent)
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
                    .foregroundStyle(themeManager.colors.accent)
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
    @StateObject private var themeManager = ThemeManager.shared
    
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
                .background(themeManager.colors.accent)
                .cornerRadius(12)
            }
            .disabled(isLoading)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationView {
        ContestListView()
    }
}
