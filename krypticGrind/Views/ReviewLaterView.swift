//
//  ReviewLaterView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct ReviewLaterView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @StateObject private var cfService = CFService.shared
    @State private var searchText = ""
    
    var filteredReviewLater: [ProblemReviewLater] {
        let reviewLater = problemDataManager.getReviewLaterProblems()
        
        if searchText.isEmpty {
            return reviewLater
        }
        
        // Filter by problem name (we'll need to get problem details from submissions)
        return reviewLater.filter { reviewLater in
            // Find the problem in recent submissions
            if let submission = cfService.recentSubmissions.first(where: { $0.problem.problemId == reviewLater.problemId }) {
                return submission.problem.name.localizedCaseInsensitiveContains(searchText) ||
                       submission.problem.index.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    ReviewLaterSearchBar(searchText: $searchText)
                        .padding()
                    
                    if filteredReviewLater.isEmpty {
                        EmptyReviewLaterView(searchText: searchText)
                    } else {
                        ReviewLaterList(reviewLaterProblems: filteredReviewLater)
                    }
                }
            }
            .background(themeManager.colors.background)
            .navigationTitle("Review Later")
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

struct ReviewLaterSearchBar: View {
    @Binding var searchText: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            
            TextField("Search problems...", text: $searchText)
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

struct ReviewLaterList: View {
    let reviewLaterProblems: [ProblemReviewLater]
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var cfService = CFService.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(reviewLaterProblems, id: \.id) { reviewLater in
                    if let submission = cfService.recentSubmissions.first(where: { $0.problem.problemId == reviewLater.problemId }) {
                        ReviewLaterListCard(submission: submission, reviewLater: reviewLater)
                    }
                }
            }
            .padding()
        }
    }
}

struct ReviewLaterListCard: View {
    let submission: CFSubmission
    let reviewLater: ProblemReviewLater
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var problemDataManager = ProblemDataManager.shared
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
                    
                    Text(reviewLater.addedAt.formatted())
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
                
                Button(action: {
                    showingProblemDetails = true
                }) {
                    Label("Details", systemImage: "info.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    problemDataManager.removeFromReviewLater(problemId: submission.problem.problemId)
                }) {
                    Label("Remove", systemImage: "bookmark.slash")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.red)
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

struct EmptyReviewLaterView: View {
    let searchText: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "bookmark")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange.gradient)
                
                VStack(spacing: 8) {
                    Text(emptyTitle)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            if searchText.isEmpty {
                Button("Start Practicing") {
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
    
    private var emptyTitle: String {
        if searchText.isEmpty {
            return "No Problems to Review"
        } else {
            return "No Matching Problems"
        }
    }
    
    private var emptyMessage: String {
        if searchText.isEmpty {
            return "Mark problems as 'Review Later' from your submissions to see them here. Great for revisiting challenging problems or studying solutions."
        } else {
            return "No problems match your search. Try different keywords or clear the search."
        }
    }
}

#Preview {
    ReviewLaterView()
} 