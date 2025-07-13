//
//  SubmissionsView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct SubmissionsView: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var colorThemeManager = ColorThemeManager()
    @State private var selectedFilter: SubmissionFilter = .all
    @State private var searchText = ""
    @State private var filteredSubmissions: [CFSubmission] = []
    @State private var isLoading = false
    
    enum SubmissionFilter: String, CaseIterable {
        case all = "All"
        case accepted = "Accepted"
        case wrongAnswer = "Wrong Answer"
        case today = "Today"
        
        var systemImage: String {
            switch self {
            case .all: return "doc.text"
            case .accepted: return "checkmark.circle"
            case .wrongAnswer: return "xmark.circle"
            case .today: return "calendar"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .accepted: return .green
            case .wrongAnswer: return .red
            case .today: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SubmissionsSearchBar(searchText: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Filter Tabs
                    FilterTabs(selectedFilter: $selectedFilter)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Submissions List
                    if isLoading {
                        ProgressView("Filtering submissions...")
                            .foregroundStyle(colorThemeManager.current.text)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredSubmissions.isEmpty {
                        EmptySubmissionsView(filter: selectedFilter)
                    } else {
                        SubmissionsList(submissions: filteredSubmissions)
                    }
                }
            }
            .navigationTitle("Submissions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            colorThemeManager.nextTheme()
                        }
                    }) {
                        Image(systemName: "paintpalette.fill")
                            .font(.title3)
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
            }
        }
        .tint(colorThemeManager.current.accent)
        .environmentObject(colorThemeManager)
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchUserSubmissions(handle: handle, count: 100)
                await filterSubmissions()
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            Task {
                await filterSubmissions()
            }
        }
        .onChange(of: searchText) { _, _ in
            Task {
                await filterSubmissions()
            }
        }
        .onChange(of: cfService.recentSubmissions) { _, _ in
            Task {
                await filterSubmissions()
            }
        }
    }
    
    // Async filtering to prevent UI hangs
    private func filterSubmissions() async {
        isLoading = true
        
        let filtered = await Task.detached(priority: .userInitiated) {
            var submissions = self.cfService.recentSubmissions
            
            // Apply filter
            switch self.selectedFilter {
            case .all:
                break
            case .accepted:
                submissions = submissions.filter { $0.isAccepted }
            case .wrongAnswer:
                submissions = submissions.filter { $0.verdict == "WRONG_ANSWER" }
            case .today:
                submissions = submissions.todaysSubmissions()
            }
            
            // Apply search
            if !self.searchText.isEmpty {
                submissions = submissions.filter { submission in
                    submission.problem.name.localizedCaseInsensitiveContains(self.searchText) ||
                    submission.problem.index.localizedCaseInsensitiveContains(self.searchText) ||
                    submission.programmingLanguage.localizedCaseInsensitiveContains(self.searchText)
                }
            }
            
            return submissions
        }.value
        
        await MainActor.run {
            filteredSubmissions = filtered
            isLoading = false
        }
    }
    }
}

struct SubmissionsSearchBar: View {
    @Binding var searchText: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search problems, languages...", text: $searchText)
                .foregroundStyle(colorThemeManager.current.text)
                .font(.system(size: 16, weight: .regular))
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

struct FilterTabs: View {
    @Binding var selectedFilter: SubmissionsView.SubmissionFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SubmissionsView.SubmissionFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct FilterTab: View {
    let filter: SubmissionsView.SubmissionFilter
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 14, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : colorThemeManager.current.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? colorThemeManager.current.accent : colorThemeManager.current.tabBar.opacity(0.9))
                    .shadow(color: isSelected ? colorThemeManager.current.accent.opacity(0.3) : Color.black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct SubmissionsList: View {
    let submissions: [CFSubmission]
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(submissions) { submission in
                    SubmissionCard(submission: submission)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}

struct SubmissionCard: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with problem info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(submission.problem.name)
                            .font(.headline.bold())
                            .foregroundStyle(colorThemeManager.current.text)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Text(submission.problem.index)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colorThemeManager.current.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(colorThemeManager.current.accent)
                            
                            if let rating = submission.problem.rating {
                                Text("\(rating)")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.ratingColor(for: rating).opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundStyle(Color.ratingColor(for: rating))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VerdictBadge(verdict: submission.verdict ?? "")
                }
                
                // Submission details
                HStack(spacing: 16) {
                    SubmissionDetailItem(
                        icon: "chevron.left.forwardslash.chevron.right",
                        title: "Language",
                        value: submission.programmingLanguage
                    )
                    
                    SubmissionDetailItem(
                        icon: "clock",
                        title: "Time",
                        value: submission.submissionDate.timeAgo()
                    )
                    
                    SubmissionDetailItem(
                        icon: "memorychip",
                        title: "Memory",
                        value: "\(submission.memoryConsumedBytes / 1024) KB"
                    )
                }
            }
            .padding(16)
            .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            SubmissionDetailSheet(submission: submission)
        }
    }
}

struct SubmissionDetailItem: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(colorThemeManager.current.text)
            }
        }
    }
}

struct VerdictBadge: View {
    let verdict: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Text(verdictDisplayText)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(verdict == "OK" ? .white : colorThemeManager.current.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(verdictColor)
            )
    }
    
    private var verdictDisplayText: String {
        switch verdict {
        case "OK": return "AC"
        case "WRONG_ANSWER": return "WA"
        case "TIME_LIMIT_EXCEEDED": return "TLE"
        case "MEMORY_LIMIT_EXCEEDED": return "MLE"
        case "RUNTIME_ERROR": return "RTE"
        case "COMPILATION_ERROR": return "CE"
        case "PRESENTATION_ERROR": return "PE"
        case "IDLENESS_LIMIT_EXCEEDED": return "ILE"
        case "SECURITY_VIOLATED": return "SV"
        case "CRASHED": return "CRASHED"
        case "INPUT_PREPARATION_CRASHED": return "IPC"
        case "CHALLENGED": return "HACK"
        case "SKIPPED": return "SKIP"
        case "TESTING": return "TESTING"
        case "REJECTED": return "REJECTED"
        default: return verdict
        }
    }
    
    private var verdictColor: Color {
        switch verdict {
        case "OK": return .green
        case "WRONG_ANSWER": return .red
        case "TIME_LIMIT_EXCEEDED": return .orange
        case "MEMORY_LIMIT_EXCEEDED": return .orange
        case "RUNTIME_ERROR": return .purple
        case "COMPILATION_ERROR": return .gray
        default: return colorThemeManager.current.accent
        }
    }
}

struct EmptySubmissionsView: View {
    let filter: SubmissionsView.SubmissionFilter
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 60))
                    .foregroundStyle(colorThemeManager.current.accent.gradient)
                
                VStack(spacing: 8) {
                    Text(emptyTitle)
                        .font(.title2.bold())
                        .foregroundStyle(colorThemeManager.current.text)
                    
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(colorThemeManager.current.text.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            if filter == .all {
                Button("Start Practicing") {
                    if let url = URL(string: "https://codeforces.com/problemset") {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all: return "No Submissions"
        case .accepted: return "No Accepted Solutions"
        case .wrongAnswer: return "No Wrong Answers"
        case .today: return "No Submissions Today"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all: return "Start solving problems to see your submissions here."
        case .accepted: return "Keep practicing! You'll get accepted solutions soon."
        case .wrongAnswer: return "Great! No wrong answers in this filter."
        case .today: return "No submissions today. Time to solve some problems!"
        }
    }
}

struct SubmissionDetailSheet: View {
    let submission: CFSubmission
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Problem Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text(submission.problem.name)
                                .font(.title2.bold())
                                .foregroundStyle(colorThemeManager.current.text)
                            
                            HStack(spacing: 8) {
                                Text(submission.problem.index)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(colorThemeManager.current.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(colorThemeManager.current.accent)
                                
                                if let rating = submission.problem.rating {
                                    Text("\(rating)")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.ratingColor(for: rating).opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(Color.ratingColor(for: rating))
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Submission Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Submission Details")
                                .font(.headline.bold())
                                .foregroundStyle(colorThemeManager.current.text)
                            
                            VStack(spacing: 12) {
                                SubmissionDetailRow(
                                    icon: "checkmark.circle",
                                    title: "Verdict",
                                    value: submission.verdictDisplayText,
                                    color: Color.verdictColor(for: submission.verdict ?? "")
                                )
                                
                                SubmissionDetailRow(
                                    icon: "chevron.left.forwardslash.chevron.right",
                                    title: "Language",
                                    value: submission.programmingLanguage,
                                    color: colorThemeManager.current.accent
                                )
                                
                                SubmissionDetailRow(
                                    icon: "clock",
                                    title: "Submission Time",
                                    value: submission.submissionDate.formatted(date: .abbreviated, time: .shortened),
                                    color: colorThemeManager.current.accent
                                )
                                
                                SubmissionDetailRow(
                                    icon: "timer",
                                    title: "Time Taken",
                                    value: "\(submission.timeConsumedMillis) ms",
                                    color: colorThemeManager.current.accent
                                )
                                
                                SubmissionDetailRow(
                                    icon: "memorychip",
                                    title: "Memory Used",
                                    value: "\(submission.memoryConsumedBytes / 1024) KB",
                                    color: colorThemeManager.current.accent
                                )
                                
                                SubmissionDetailRow(
                                    icon: "number",
                                    title: "Test Case",
                                    value: "\(submission.passedTestCount)",
                                    color: colorThemeManager.current.accent
                                )
                            }
                        }
                        .padding()
                        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Problem Link
                        if let url = URL(string: submission.problem.problemUrl) {
                            Link(destination: url) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.subheadline)
                                    
                                    Text("View Problem on Codeforces")
                                        .font(.subheadline.weight(.medium))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .foregroundStyle(colorThemeManager.current.accent)
                                .padding()
                                .background(colorThemeManager.current.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Submission Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(colorThemeManager.current.tabBar, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

struct SubmissionDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(colorThemeManager.current.text.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(colorThemeManager.current.text)
        }
    }
}

#Preview {
    SubmissionsView()
}
