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
                SubmissionsSearchBar(searchText: $searchText)
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

struct SubmissionsSearchBar: View {
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
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @StateObject private var cfService = CFService.shared
    
    @State private var showingNotesSheet = false
    @State private var showingSolutionSheet = false
    @State private var showingSourceCode = false
    @State private var sourceCode: String?
    @State private var isLoadingSourceCode = false
    
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
                        
                        // Action Buttons
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Actions")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                            
                            VStack(spacing: 8) {
                                // Review Later Button
                                Button(action: {
                                    if problemDataManager.isInReviewLater(problemId: submission.problem.problemId) {
                                        problemDataManager.removeFromReviewLater(problemId: submission.problem.problemId)
                                    } else {
                                        problemDataManager.addToReviewLater(problemId: submission.problem.problemId)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: problemDataManager.isInReviewLater(problemId: submission.problem.problemId) ? "bookmark.fill" : "bookmark")
                                        Text(problemDataManager.isInReviewLater(problemId: submission.problem.problemId) ? "Remove from Review Later" : "Add to Review Later")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(problemDataManager.isInReviewLater(problemId: submission.problem.problemId) ? .orange.opacity(0.2) : .blue.opacity(0.2))
                                    .foregroundStyle(problemDataManager.isInReviewLater(problemId: submission.problem.problemId) ? .orange : .blue)
                                    .cornerRadius(8)
                                }
                                
                                // Notes Button
                                Button(action: {
                                    showingNotesSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "note.text")
                                        Text("Notes (\(problemDataManager.getNotes(for: submission.problem.problemId).count))")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .cornerRadius(8)
                                }
                                
                                // View Source Code Button
                                Button(action: {
                                    showingSourceCode = true
                                    if sourceCode == nil {
                                        loadSourceCode()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text")
                                        Text("View Source Code")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(.purple.opacity(0.2))
                                    .foregroundStyle(.purple)
                                    .cornerRadius(8)
                                }
                                
                                // Solutions Gallery Button
                                Button(action: {
                                    showingSolutionSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "folder")
                                        Text("Solutions (\(problemDataManager.getSolutions(for: submission.problem.problemId).count))")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(.indigo.opacity(0.2))
                                    .foregroundStyle(.indigo)
                                    .cornerRadius(8)
                                }
                            }
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
            .sheet(isPresented: $showingNotesSheet) {
                NotesSheet(problemId: submission.problem.problemId, problemName: submission.problem.name)
            }
            .sheet(isPresented: $showingSolutionSheet) {
                SolutionsSheet(problemId: submission.problem.problemId, problemName: submission.problem.name, submission: submission)
            }
            .sheet(isPresented: $showingSourceCode) {
                SourceCodeSheet(sourceCode: sourceCode, isLoading: isLoadingSourceCode, submission: submission)
            }
        }
    }
    
    private func loadSourceCode() {
        isLoadingSourceCode = true
        Task {
            sourceCode = await cfService.fetchSubmissionSourceCode(submissionId: submission.creationTimeSeconds)
            isLoadingSourceCode = false
        }
    }
}

// MARK: - Notes Sheet
struct NotesSheet: View {
    let problemId: String
    let problemName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @State private var newNoteText = ""
    @State private var showingAddNote = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Notes List
                    if problemDataManager.getNotes(for: problemId).isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "note.text")
                                .font(.system(size: 60))
                                .foregroundStyle(.green.gradient)
                            
                            VStack(spacing: 8) {
                                Text("No Notes Yet")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                
                                Text("Add your first note for this problem to track your thoughts and solutions.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(problemDataManager.getNotes(for: problemId)) { note in
                                    NoteCard(note: note)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddNote = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(themeManager.colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteSheet(problemId: problemId, problemName: problemName)
            }
        }
    }
}

struct NoteCard: View {
    let note: ProblemNote
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @State private var showingEditNote = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(note.note)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Menu {
                    Button("Edit") {
                        showingEditNote = true
                    }
                    
                    Button("Delete", role: .destructive) {
                        problemDataManager.deleteNote(note)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Text(note.createdAt.formatted())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingEditNote) {
            EditNoteSheet(note: note)
        }
    }
}

struct AddNoteSheet: View {
    let problemId: String
    let problemName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @State private var noteText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Note")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                        
                        Text("Problem: \(problemName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextEditor(text: $noteText)
                        .frame(minHeight: 200)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            problemDataManager.addNote(for: problemId, note: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                    }
                    .foregroundStyle(themeManager.colors.accent)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct EditNoteSheet: View {
    let note: ProblemNote
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @State private var noteText: String
    
    init(note: ProblemNote) {
        self.note = note
        self._noteText = State(initialValue: note.note)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit Note")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                        
                        Text("Created: \(note.createdAt.formatted())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextEditor(text: $noteText)
                        .frame(minHeight: 200)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            problemDataManager.updateNote(note, newText: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                    }
                    .foregroundStyle(themeManager.colors.accent)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Solutions Sheet
struct SolutionsSheet: View {
    let problemId: String
    let problemName: String
    let submission: CFSubmission
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @StateObject private var cfService = CFService.shared
    @State private var showingAddSolution = false
    @State private var isLoadingSourceCode = false
    @State private var sourceCode: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Solutions List
                    if problemDataManager.getSolutions(for: problemId).isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "folder")
                                .font(.system(size: 60))
                                .foregroundStyle(.indigo.gradient)
                            
                            VStack(spacing: 8) {
                                Text("No Solutions Saved")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                
                                Text("Save your solutions to build a personal code gallery for this problem.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(problemDataManager.getSolutions(for: problemId)) { solution in
                                    SolutionCard(solution: solution)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Solutions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSolution = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(themeManager.colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSolution) {
                AddSolutionSheet(problemId: problemId, problemName: problemName, submission: submission)
            }
        }
    }
}

struct SolutionCard: View {
    let solution: ProblemSolution
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @State private var showingSolutionDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(solution.title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    if let description = solution.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("View Code") {
                        showingSolutionDetail = true
                    }
                    
                    Button("Delete", role: .destructive) {
                        problemDataManager.deleteSolution(solution)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Label(solution.language, systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(solution.code.components(separatedBy: .newlines).count) lines", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(solution.savedAt.formatted())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingSolutionDetail) {
            SolutionDetailSheet(solution: solution)
        }
    }
}

struct AddSolutionSheet: View {
    let problemId: String
    let problemName: String
    let submission: CFSubmission
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @StateObject private var cfService = CFService.shared
    @State private var title = ""
    @State private var description = ""
    @State private var isLoadingSourceCode = false
    @State private var sourceCode: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Save Solution")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                        
                        Text("Problem: \(problemName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("Solution title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("Brief description", text: $description)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if isLoadingSourceCode {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading source code...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    } else if let code = sourceCode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Source Code")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            ScrollView {
                                Text(code)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }
                            .frame(maxHeight: 200)
                        }
                    } else {
                        Button("Load Source Code") {
                            loadSourceCode()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Save Solution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let solution = ProblemSolution(
                                problemId: problemId,
                                submissionId: submission.creationTimeSeconds,
                                code: sourceCode ?? "// Source code not available",
                                language: submission.programmingLanguage,
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            problemDataManager.saveSolution(solution)
                            dismiss()
                        }
                    }
                    .foregroundStyle(themeManager.colors.accent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func loadSourceCode() {
        isLoadingSourceCode = true
        Task {
            sourceCode = await cfService.fetchSubmissionSourceCode(submissionId: submission.creationTimeSeconds)
            isLoadingSourceCode = false
        }
    }
}

struct SolutionDetailSheet: View {
    let solution: ProblemSolution
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Solution Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Solution Information")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                            
                            InfoRow(title: "Title", value: solution.title)
                            if let description = solution.description {
                                InfoRow(title: "Description", value: description)
                            }
                            InfoRow(title: "Language", value: solution.language)
                            InfoRow(title: "Lines", value: "\(solution.code.components(separatedBy: .newlines).count)")
                            InfoRow(title: "Saved", value: solution.savedAt.formatted())
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        
                        // Source Code
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Source Code")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                            
                            ScrollView {
                                Text(solution.code)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .frame(maxHeight: 400)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                }
            }
            .navigationTitle("Solution Details")
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

// MARK: - Source Code Sheet
struct SourceCodeSheet: View {
    let sourceCode: String?
    let isLoading: Bool
    let submission: CFSubmission
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Loading source code...")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Fetching from Codeforces")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let code = sourceCode {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // Submission Info
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Submission Info")
                                        .font(.headline.bold())
                                        .foregroundStyle(.primary)
                                    
                                    HStack {
                                        Label(submission.programmingLanguage, systemImage: "chevron.left.forwardslash.chevron.right")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("\(code.components(separatedBy: .newlines).count) lines")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                                
                                // Source Code
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Source Code")
                                        .font(.headline.bold())
                                        .foregroundStyle(.primary)
                                    
                                    ScrollView {
                                        Text(code)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding()
                                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                    }
                                    .frame(maxHeight: 500)
                                }
                                .padding()
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .padding()
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 60))
                                .foregroundStyle(.red.gradient)
                            
                            VStack(spacing: 8) {
                                Text("Source Code Not Available")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                
                                Text("Unable to fetch the source code for this submission. It might be private or the submission ID is invalid.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    }
                }
            }
            .navigationTitle("Source Code")
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
