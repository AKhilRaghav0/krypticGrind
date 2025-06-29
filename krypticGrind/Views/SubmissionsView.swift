//
//  SubmissionsView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct SubmissionsView: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedFilter: SubmissionFilter = .all
    @State private var searchText = ""
    
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
    
    var filteredSubmissions: [CFSubmission] {
        var submissions = cfService.recentSubmissions
        
        // Apply filter
        switch selectedFilter {
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
        if !searchText.isEmpty {
            submissions = submissions.filter { submission in
                submission.problem.name.localizedCaseInsensitiveContains(searchText) ||
                submission.problem.index.localizedCaseInsensitiveContains(searchText) ||
                submission.programmingLanguage.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return submissions
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(searchText: $searchText)
                    .padding()
                
                // Filter Tabs
                FilterTabs(selectedFilter: $selectedFilter)
                    .padding(.horizontal)
                
                // Submissions List
                if filteredSubmissions.isEmpty {
                    EmptySubmissionsView(filter: selectedFilter)
                } else {
                    SubmissionsList(submissions: filteredSubmissions)
                }
            }
            .background(themeManager.colors.background)
            .navigationTitle("Submissions")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchUserSubmissions(handle: handle, count: 100)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            
            TextField("Search problems, languages...", text: $searchText)
                .foregroundStyle(.primary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterTabs: View {
    @Binding var selectedFilter: SubmissionsView.SubmissionFilter
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SubmissionsView.SubmissionFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterTab: View {
    let filter: SubmissionsView.SubmissionFilter
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.systemImage)
                    .font(.subheadline)
                
                Text(filter.rawValue)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? filter.color.gradient : themeManager.colors.surface.gradient,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct SubmissionsList: View {
    let submissions: [CFSubmission]
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(submissions) { submission in
                    SubmissionCard(submission: submission)
                }
            }
            .padding()
        }
    }
}

struct SubmissionCard: View {
    let submission: CFSubmission
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingProblemDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(submission.problem.name)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        // Problem index
                        Text(submission.problem.index)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(.blue)
                        
                        // Problem rating
                        if let rating = submission.problem.rating {
                            Text("\(rating)")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.ratingColor(for: rating).opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(Color.ratingColor(for: rating))
                        }
                    }
                }
                
                Spacer()
                
                // Verdict and time
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: submission.isAccepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.subheadline)
                        
                        Text(submission.verdictDisplayText)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Color.verdictColor(for: submission.verdict ?? ""))
                    
                    Text(submission.submissionDate.timeAgo())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Programming language and additional details
            HStack(spacing: 16) {
                Label(submission.programmingLanguage, systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if submission.memoryConsumedBytes > 0 {
                    Label("\(submission.memoryConsumedBytes / 1024) KB", systemImage: "memorychip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if submission.timeConsumedMillis > 0 {
                    Label("\(submission.timeConsumedMillis) ms", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Tags (if any)
            if !submission.problem.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(submission.problem.tags.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                                .foregroundStyle(.purple)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    if let url = URL(string: submission.problem.problemUrl) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("View Problem", systemImage: "safari")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(themeManager.colors.accent)
                }
                
                Spacer()
                
                Button(action: {
                    showingProblemDetails = true
                }) {
                    Label("Details", systemImage: "info.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingProblemDetails) {
            ProblemDetailSheet(submission: submission)
        }
    }
}

struct EmptySubmissionsView: View {
    let filter: SubmissionsView.SubmissionFilter
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 60))
                    .foregroundStyle(filter.color.gradient)
                
                VStack(spacing: 8) {
                    Text("No \(filter.rawValue) Submissions")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            if filter == .all {
                Button("Start Coding") {
                    // Handle action to open Codeforces
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
    
    private var emptyMessage: String {
        switch filter {
        case .all:
            return "Submit some problems on Codeforces to see your submission history here"
        case .accepted:
            return "No accepted submissions yet. Keep practicing and you'll get there!"
        case .wrongAnswer:
            return "No wrong answers found. Your accuracy is impressive!"
        case .today:
            return "No submissions today. Ready to tackle some problems?"
        }
    }
}

struct ProblemDetailSheet: View {
    let submission: CFSubmission
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Problem Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Problem Information")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                            
                            InfoRow(title: "Name", value: submission.problem.name)
                            InfoRow(title: "Index", value: submission.problem.index)
                            InfoRow(title: "Difficulty", value: submission.problem.difficulty)
                            
                            if let rating = submission.problem.rating {
                                InfoRow(title: "Rating", value: "\(rating)")
                            }
                            
                            if let contestId = submission.problem.contestId {
                                InfoRow(title: "Contest", value: "\(contestId)")
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Submission Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Submission Details")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                            
                            InfoRow(title: "Verdict", value: submission.verdictDisplayText)
                            InfoRow(title: "Language", value: submission.programmingLanguage)
                            InfoRow(title: "Time", value: "\(submission.timeConsumedMillis) ms")
                            InfoRow(title: "Memory", value: "\(submission.memoryConsumedBytes / 1024) KB")
                            InfoRow(title: "Tests Passed", value: "\(submission.passedTestCount)")
                            InfoRow(title: "Submitted", value: submission.submissionDate.formatted())
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Tags
                        if !submission.problem.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tags")
                                    .font(.headline.bold())
                                    .foregroundStyle(.primary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 100))
                                ], spacing: 8) {
                                    ForEach(submission.problem.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(themeManager.colors.highlight.opacity(0.2))
                                            .foregroundStyle(themeManager.colors.highlight)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Submission Details")
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

#Preview {
    NavigationView {
        SubmissionsView()
    }
}
