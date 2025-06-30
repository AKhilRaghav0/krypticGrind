//
//  AIProblemSuggestionCard.swift
//  KrypticGrind
//
//  Created by akhil on 03/07/25.
//

import SwiftUI
import Foundation

// MARK: - AI Problem Suggestion Card
struct AIProblemSuggestionCard: View {
    let user: CFUser
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var cfService = CFService.shared
    @State private var tags: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("AI Coach Suggestions")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if !isLoading {
                    Button(action: { Task { await fetchTags() } }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating personalized tags...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else if tags.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                    Text("Get Personalized Practice Tags")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    Text("Let AI suggest Codeforces topics for you to practice next")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Generate Suggestions") {
                        Task { await fetchTags() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(tags, id: \.self) { tag in
                        PracticeTagRow(tag: tag)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task {
            if tags.isEmpty && !isLoading {
                await fetchTags()
            }
        }
    }
    
    private func fetchTags() async {
        isLoading = true
        let tags = await geminiService.generatePracticeTags(user: user, submissions: cfService.recentSubmissions)
        await MainActor.run {
            self.tags = tags
            self.isLoading = false
        }
    }
}

struct PracticeTagRow: View {
    let tag: String
    @Environment(\.openURL) private var openURL
    @State private var problems: [CFProblem] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Text(tag.capitalized)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    let urlString = "https://codeforces.com/problemset?tags=\(tag)&order=BY_RATING_ASC"
                    if let url = URL(string: urlString) {
                        openURL(url)
                    }
                } label: {
                    Text("All Problems")
                        .font(.footnote.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            if isLoading {
                ProgressView().scaleEffect(0.7)
            } else if !problems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(problems.prefix(3), id: \.problemUrl) { problem in
                        Button(action: {
                            if let url = URL(string: problem.problemUrl) {
                                openURL(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(.orange)
                                Text(problem.name)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(problem.difficulty)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("No problems found.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        .task {
            if problems.isEmpty && !isLoading {
                await fetchProblems()
            }
        }
    }
    
    private func fetchProblems() async {
        isLoading = true
        let cacheKey = "cf_tag_\(tag)_problems"
        let cacheTimeKey = "cf_tag_\(tag)_problems_time"
        let now = Date()
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let timestamp = UserDefaults.standard.object(forKey: cacheTimeKey) as? Date,
           now.timeIntervalSince(timestamp) < 86400,
           let cached = try? JSONDecoder().decode([CFProblem].self, from: data) {
            self.problems = cached
            self.isLoading = false
            return
        }
        guard let url = URL(string: "https://codeforces.com/api/problemset.problems?tags=\(tag)") else {
            self.isLoading = false
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let apiResponse = try? JSONDecoder().decode(CFProblemsetResponse.self, from: data) {
                let problems = apiResponse.result.problems.prefix(10).map { $0 }
                self.problems = Array(problems)
                if let encoded = try? JSONEncoder().encode(self.problems) {
                    UserDefaults.standard.set(encoded, forKey: cacheKey)
                    UserDefaults.standard.set(now, forKey: cacheTimeKey)
                }
            }
        } catch {
            print("Failed to fetch problems for tag \(tag): \(error)")
        }
        self.isLoading = false
    }
}

#Preview {
    Text("Preview not available")
} 
