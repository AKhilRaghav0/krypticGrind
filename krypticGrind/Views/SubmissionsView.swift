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
            ZStack {
                themeManager.colors.background
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
                    if filteredSubmissions.isEmpty {
                        EmptySubmissionsView(filter: selectedFilter)
                    } else {
                        SubmissionsList(submissions: filteredSubmissions)
                    }
                }
            }
            .navigationTitle("Submissions")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(themeManager.colors.accent)
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
                .foregroundStyle(themeManager.colors.textSecondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search problems, languages...", text: $searchText)
                .foregroundStyle(themeManager.colors.textPrimary)
                .font(.system(size: 16, weight: .regular))
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeManager.colors.textSecondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

struct FilterTabs: View {
    @Binding var selectedFilter: SubmissionsView.SubmissionFilter
    @StateObject private var themeManager = ThemeManager.shared
    
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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 14, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : themeManager.colors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? themeManager.colors.accent : Color(.systemBackground).opacity(0.9))
                    .shadow(color: isSelected ? themeManager.colors.accent.opacity(0.3) : Color.black.opacity(0.05), radius: 8, y: 2)
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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with problem info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(submission.problem.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeManager.colors.textPrimary)
                        .lineLimit(2)
                    
                    Text(submission.problem.index)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(themeManager.colors.accent)
                }
                
                Spacer()
                
                // Verdict badge
                VerdictBadge(verdict: submission.verdict ?? "UNKNOWN")
            }
            
            // Submission details
            HStack(spacing: 16) {
                DetailItem(
                    icon: "chevron.left.forwardslash.chevron.right",
                    text: submission.programmingLanguage,
                    color: themeManager.colors.textSecondary
                )
                
                DetailItem(
                    icon: "clock",
                    text: submission.submissionDate.formatted(date: .abbreviated, time: .shortened),
                    color: themeManager.colors.textSecondary
                )
                
                if let rating = submission.problem.rating {
                    DetailItem(
                        icon: "star.fill",
                        text: "\(rating)",
                        color: Color.ratingColor(for: rating)
                    )
                }
            }
            
            // Problem link
            if let url = URL(string: submission.problem.problemUrl) {
                Link(destination: url) {
                    HStack {
                        Text("View Problem")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(themeManager.colors.accent)
                    )
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

struct VerdictBadge: View {
    let verdict: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Text(verdictDisplayText)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
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
        default: return .blue
        }
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

struct EmptySubmissionsView: View {
    let filter: SubmissionsView.SubmissionFilter
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: emptyIcon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(themeManager.colors.textSecondary)
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(themeManager.colors.textPrimary)
                
                Text(emptyMessage)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(themeManager.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var emptyIcon: String {
        switch filter {
        case .all: return "doc.text"
        case .accepted: return "checkmark.circle"
        case .wrongAnswer: return "xmark.circle"
        case .today: return "calendar"
        }
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
        case .all: return "Start solving problems to see your submissions here"
        case .accepted: return "Keep practicing! Accepted solutions will appear here"
        case .wrongAnswer: return "No wrong answers found. Great job!"
        case .today: return "No submissions made today. Time to practice!"
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
