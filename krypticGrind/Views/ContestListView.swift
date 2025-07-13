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
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingFinishedContests = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Toggle between upcoming and finished
                    ContestToggle(showingFinished: $showingFinishedContests)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    if showingFinishedContests {
                        FinishedContestsList()
                    } else {
                        UpcomingContestsList()
                    }
                }
            }
            .navigationTitle("Contests")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(themeManager.colors.accent)
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(showingFinished ? themeManager.colors.textSecondary : themeManager.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(showingFinished ? themeManager.colors.surface.opacity(0.9) : themeManager.colors.accent)
                            .shadow(color: showingFinished ? Color.black.opacity(0.05) : themeManager.colors.accent.opacity(0.3), radius: 8, y: 2)
                    )
            }
            
            Button(action: {
                showingFinished = true
            }) {
                Text("Recent")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(showingFinished ? themeManager.colors.textPrimary : themeManager.colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(showingFinished ? themeManager.colors.accent : themeManager.colors.surface.opacity(0.9))
                            .shadow(color: showingFinished ? themeManager.colors.accent.opacity(0.3) : Color.black.opacity(0.05), radius: 8, y: 2)
                    )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeManager.colors.surface.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
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
                        .foregroundStyle(themeManager.colors.textSecondary)
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
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingDetails = false
    @State private var showLiveActivityError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with contest info
            VStack(alignment: .leading, spacing: 8) {
                Text(contest.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(themeManager.colors.textPrimary)
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
                    color: themeManager.colors.textSecondary
                )
                
                DetailItem(
                    icon: "clock",
                    text: contest.duration,
                    color: themeManager.colors.textSecondary
                )
                
                DetailItem(
                    icon: "person.3",
                    text: contest.type.capitalized,
                    color: themeManager.colors.textSecondary
                )
            }
            
            // Action buttons
            HStack(spacing: 12) {
                ActionButton(
                    title: "Register",
                    icon: "arrow.right.circle.fill",
                    color: themeManager.colors.accent
                ) {
                    if let url = URL(string: "https://codeforces.com/contest/\(contest.id)/register") {
                        UIApplication.shared.open(url)
                    }
                }
                
                ActionButton(
                    title: "Notify",
                    icon: "bell.fill",
                    color: themeManager.colors.warning
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
                .fill(themeManager.colors.surface.opacity(0.9))
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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Text(type.capitalized)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(themeManager.colors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(themeManager.colors.accent)
            )
    }
}

struct ContestCountryBadge: View {
    let country: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Text(country)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(themeManager.colors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(themeManager.colors.textSecondary)
            )
    }
}

struct ContestPhaseBadge: View {
    let phase: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Text(phaseDisplayText)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(themeManager.colors.textPrimary)
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
        case "BEFORE": return themeManager.colors.accent
        case "CODING": return themeManager.colors.success
        case "PENDING_SYSTEM_TEST": return themeManager.colors.warning
        case "SYSTEM_TEST": return themeManager.colors.warning
        case "FINISHED": return themeManager.colors.textSecondary
        default: return themeManager.colors.textSecondary
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(themeManager.colors.textPrimary)
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
    @StateObject private var themeManager = ThemeManager.shared
    
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
                    .foregroundStyle(themeManager.colors.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(themeManager.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(themeManager.colors.textSecondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
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
                        .foregroundStyle(themeManager.colors.textPrimary)
                        .lineLimit(2)
                    
                    if let startDate = contest.startDate {
                        Text("Held on \(startDate.formatted())")
                            .font(.subheadline)
                            .foregroundStyle(themeManager.colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Text("Finished")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.colors.textSecondary.opacity(0.2))
                    .foregroundStyle(themeManager.colors.textSecondary)
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
        .background(themeManager.colors.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ContestInfoItem: View {
    let title: String
    let value: String
    let icon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(themeManager.colors.textSecondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(themeManager.colors.textSecondary)
                
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(themeManager.colors.textPrimary)
            }
        }
    }
}

struct EmptyContestsView: View {
    let isUpcoming: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isUpcoming ? "calendar" : "checkmark.circle")
                .font(.system(size: 50))
                .foregroundStyle(themeManager.colors.textSecondary)
            
            Text(isUpcoming ? "No upcoming contests" : "Loading recent contests...")
                .font(.title3.bold())
                .foregroundStyle(themeManager.colors.textPrimary)
            
            Text(isUpcoming ? 
                 "Check back later for new contests" : 
                 "Please wait while we fetch contest data"
            )
                .font(.subheadline)
                .foregroundStyle(themeManager.colors.textSecondary)
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
                                .foregroundStyle(themeManager.colors.textPrimary)
                            
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
                        .background(themeManager.colors.surface, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Contest Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline.bold())
                                .foregroundStyle(themeManager.colors.textPrimary)
                            
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
                        .background(themeManager.colors.surface, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Description
                        if let description = contest.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.headline.bold())
                                    .foregroundStyle(themeManager.colors.textPrimary)
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundStyle(themeManager.colors.textSecondary)
                            }
                            .padding()
                            .background(themeManager.colors.surface, in: RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Action Button
                        Button(action: {
                            if let url = URL(string: contest.contestUrl) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Open in Codeforces", systemImage: "link")
                                .font(.headline.bold())
                                .foregroundStyle(themeManager.colors.textPrimary)
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
