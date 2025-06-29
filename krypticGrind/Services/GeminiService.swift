//
//  GeminiService.swift
//  KrypticGrind
//
//  Created by akhil on 01/07/25.
//

import Foundation
import Combine

// MARK: - Gemini API Models
struct GeminiRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig?
    
    struct Content: Codable {
        let parts: [Part]
        
        struct Part: Codable {
            let text: String
        }
    }
    
    struct GenerationConfig: Codable {
        let temperature: Double
        let topK: Int
        let topP: Double
        let maxOutputTokens: Int
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        let finishReason: String?
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String
            }
        }
    }
}

// MARK: - AI Suggestion Models
struct AISuggestion {
    let id = UUID()
    let title: String
    let description: String
    let type: SuggestionType
    let priority: Priority
    let actionText: String
    let actionURL: String?
    
    enum SuggestionType {
        case practice, improvement, topic, contest, streak
        
        var icon: String {
            switch self {
            case .practice: return "book.fill"
            case .improvement: return "chart.line.uptrend.xyaxis"
            case .topic: return "tag.fill"
            case .contest: return "trophy.fill"
            case .streak: return "flame.fill"
            }
        }
        
        var color: String {
            switch self {
            case .practice: return "blue"
            case .improvement: return "green"
            case .topic: return "purple"
            case .contest: return "orange"
            case .streak: return "red"
            }
        }
    }
    
    enum Priority: Int, CaseIterable {
        case low = 1, medium = 2, high = 3
        
        var displayText: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
}

// MARK: - Problem Recommendation Model
struct ProblemRecommendation {
    let id = UUID()
    let title: String
    let difficulty: String
    let topic: String
    let reason: String
    let codeforcesURL: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: String {
            switch self {
            case .high: return "red"
            case .medium: return "orange"
            case .low: return "blue"
            }
        }
        
        var icon: String {
            switch self {
            case .high: return "exclamationmark.circle.fill"
            case .medium: return "info.circle.fill"
            case .low: return "lightbulb.fill"
            }
        }
    }
}

// MARK: - Gemini AI Service
@MainActor
class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
    private let apiKey = "AIzaSyAA6sSSrUYbfHZePNn0TH2abg8XoSiwuYs"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    @Published var isLoading = false
    @Published var suggestions: [AISuggestion] = []
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Generate AI Suggestions
    func generateSuggestions(
        userStats: UserStats,
        submissions: [CFSubmission],
        user: CFUser?
    ) async {
        isLoading = true
        error = nil
        
        do {
            let prompt = createPrompt(userStats: userStats, submissions: submissions, user: user)
            let response = try await callGeminiAPI(prompt: prompt)
            let parsedSuggestions = parseSuggestions(from: response)
            
            self.suggestions = parsedSuggestions
        } catch {
            self.error = "Failed to generate suggestions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Create Intelligent Prompt
    private func createPrompt(userStats: UserStats, submissions: [CFSubmission], user: CFUser?) -> String {
        let acceptedCount = submissions.filter { $0.isAccepted }.count
        let totalSubmissions = submissions.count
        let acceptanceRate = totalSubmissions > 0 ? Double(acceptedCount) / Double(totalSubmissions) * 100 : 0
        
        // Analyze user's problem-solving patterns
        let ratingAnalysis = analyzeRatingDistribution(submissions: submissions)
        let topicAnalysis = analyzeTopicWeaknesses(submissions: submissions)
        let difficultyProgression = analyzeDifficultyProgression(submissions: submissions, userRating: user?.rating ?? 0)
        let recentPerformance = analyzeRecentPerformance(submissions: submissions)
        let languageStats = Dictionary(grouping: submissions) { $0.programmingLanguage }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return """
        You are an AI coach for competitive programming. Analyze this Codeforces user's data and recommend SPECIFIC problems they should solve next.
        
        USER PROFILE:
        - Current Rating: \(user?.rating ?? 0)
        - Max Rating: \(user?.maxRating ?? 0)
        - Rank: \(user?.rank ?? "Unrated")
        - Total Submissions: \(totalSubmissions)
        - Accepted Solutions: \(acceptedCount)
        - Acceptance Rate: \(String(format: "%.1f", acceptanceRate))%
        
        PROBLEM DIFFICULTY ANALYSIS:
        \(ratingAnalysis)
        
        TOPIC WEAKNESSES IDENTIFIED:
        \(topicAnalysis)
        
        DIFFICULTY PROGRESSION ANALYSIS:
        \(difficultyProgression)
        
        RECENT PERFORMANCE (Last 2 weeks):
        \(recentPerformance)
        
        PRIMARY LANGUAGE: \(languageStats.first?.key ?? "Not specified")
        
        Based on this analysis, provide exactly 4-6 SPECIFIC problem recommendations in this format:
        
        SUGGESTION_1:
        Type: practice
        Priority: high
        Title: [Specific topic like "Dynamic Programming - LCS Problems"]
        Description: [Why this topic is important for their growth and what rating range to target]
        Action: Practice Now
        URL: https://codeforces.com/problemset?tags=[specific-tag]
        
        SUGGESTION_2:
        Type: improvement
        Priority: medium
        Title: [Specific weakness like "Graph Theory - DFS/BFS"]
        Description: [Detailed explanation of why they need this and expected improvement]
        Action: Study Topic
        URL: https://codeforces.com/problemset?tags=[specific-tag]
        
        [Continue for 4-6 suggestions]
        
        Focus on:
        1. Identifying their current skill level and next logical step
        2. Recommending problems 100-200 rating points above their current level
        3. Addressing their weakest topics first
        4. Suggesting rating-appropriate contest problems
        5. Building consistency in problem-solving patterns
        
        Make each recommendation specific with exact Codeforces problem tags and rating ranges!
        """
    }
    
    // MARK: - Advanced Analysis Methods
    private func analyzeRatingDistribution(submissions: [CFSubmission]) -> String {
        let acceptedSubmissions = submissions.filter { $0.isAccepted }
        let ratingCounts = Dictionary(grouping: acceptedSubmissions) { submission in
            let rating = submission.problem.rating ?? 0
            switch rating {
            case 0..<800: return "Beginner (0-799)"
            case 800..<1200: return "Easy (800-1199)"
            case 1200..<1600: return "Medium (1200-1599)"
            case 1600..<2000: return "Hard (1600-1999)"
            case 2000..<2400: return "Expert (2000-2399)"
            default: return "Master (2400+)"
            }
        }.mapValues { $0.count }
        
        let totalSolved = acceptedSubmissions.count
        let distribution = ratingCounts.map { category, count in
            let percentage = totalSolved > 0 ? Double(count) / Double(totalSolved) * 100 : 0
            return "\(category): \(count) problems (\(String(format: "%.1f", percentage))%)"
        }.joined(separator: "\n")
        
        return distribution
    }
    
    private func analyzeTopicWeaknesses(submissions: [CFSubmission]) -> String {
        let acceptedSubmissions = submissions.filter { $0.isAccepted }
        let allTags = acceptedSubmissions.flatMap { $0.problem.tags }
        let tagCounts = Dictionary(grouping: allTags) { $0 }.mapValues { $0.count }
        
        // Common competitive programming topics
        let importantTopics = ["implementation", "math", "greedy", "dp", "graph", "data structures", 
                              "binary search", "two pointers", "sorting", "strings", "number theory", 
                              "combinatorics", "geometry", "brute force"]
        
        let weakTopics = importantTopics.filter { topic in
            let count = tagCounts[topic] ?? 0
            return count < 3 // Less than 3 problems solved in this topic
        }
        
        let strongTopics = tagCounts.sorted { $0.value > $1.value }.prefix(3)
        
        return """
        Weak Areas (need focus): \(weakTopics.isEmpty ? "None identified" : weakTopics.joined(separator: ", "))
        Strong Areas: \(strongTopics.map { "\($0.key) (\($0.value))" }.joined(separator: ", "))
        """
    }
    
    private func analyzeDifficultyProgression(submissions: [CFSubmission], userRating: Int) -> String {
        let acceptedSubmissions = submissions.filter { $0.isAccepted }
        let recentAccepted = acceptedSubmissions.prefix(20) // Last 20 accepted
        
        let avgRecentRating = recentAccepted.compactMap { ($0.problem.rating ?? 0) > 0 ? $0.problem.rating : nil }
            .reduce(0, +) / max(recentAccepted.count, 1)
        
        let recommendedRange = userRating > 0 ? userRating : avgRecentRating
        let nextLevelMin = recommendedRange + 100
        let nextLevelMax = recommendedRange + 300
        
        return """
        Average problem rating solved recently: \(avgRecentRating)
        Current user rating: \(userRating)
        Recommended next difficulty range: \(nextLevelMin) - \(nextLevelMax)
        """
    }
    
    private func analyzeRecentPerformance(submissions: [CFSubmission]) -> String {
        let twoWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date()
        let recentSubmissions = submissions.filter { $0.submissionDate >= twoWeeksAgo }
        let recentAccepted = recentSubmissions.filter { $0.isAccepted }
        
        let recentRate = recentSubmissions.count > 0 ? 
            Double(recentAccepted.count) / Double(recentSubmissions.count) * 100 : 0
        
        let uniqueProblems = Set(recentAccepted.map { $0.problem.name }).count
        
        return """
        Recent submissions: \(recentSubmissions.count)
        Recent acceptance rate: \(String(format: "%.1f", recentRate))%
        Unique problems solved: \(uniqueProblems)
        Activity level: \(recentSubmissions.count > 10 ? "High" : recentSubmissions.count > 5 ? "Medium" : "Low")
        """
    }
    
    private func getRecentActivitySummary(submissions: [CFSubmission]) -> String {
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let recentSubmissions = submissions.filter { $0.submissionDate >= lastWeek }
        
        let recentAccepted = recentSubmissions.filter { $0.isAccepted }.count
        let uniqueProblems = Set(recentSubmissions.map { $0.problem.name }).count
        
        return """
        - Last 7 days: \(recentSubmissions.count) submissions, \(recentAccepted) accepted
        - Unique problems attempted: \(uniqueProblems)
        - Most recent submission: \(submissions.first?.submissionDate.timeAgo() ?? "No recent activity")
        """
    }
    
    // MARK: - API Call
    private func callGeminiAPI(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let request = GeminiRequest(
            contents: [
                GeminiRequest.Content(
                    parts: [GeminiRequest.Content.Part(text: prompt)]
                )
            ],
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 1024
            )
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        return text
    }
    
    // MARK: - Parse Suggestions
    private func parseSuggestions(from response: String) -> [AISuggestion] {
        let suggestions = response.components(separatedBy: "SUGGESTION_")
            .dropFirst() // Remove empty first component
            .compactMap { suggestionText -> AISuggestion? in
                let lines = suggestionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                
                var type: AISuggestion.SuggestionType = .practice
                var priority: AISuggestion.Priority = .medium
                var title = ""
                var description = ""
                var action = ""
                var url: String? = nil
                
                for line in lines {
                    if line.hasPrefix("Type:") {
                        let typeString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                        switch typeString.lowercased() {
                        case "practice": type = .practice
                        case "improvement": type = .improvement
                        case "topic": type = .topic
                        case "contest": type = .contest
                        case "streak": type = .streak
                        default: type = .practice
                        }
                    } else if line.hasPrefix("Priority:") {
                        let priorityString = String(line.dropFirst(9)).trimmingCharacters(in: .whitespaces)
                        switch priorityString.lowercased() {
                        case "high": priority = .high
                        case "medium": priority = .medium
                        case "low": priority = .low
                        default: priority = .medium
                        }
                    } else if line.hasPrefix("Title:") {
                        title = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("Description:") {
                        description = String(line.dropFirst(12)).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("Action:") {
                        action = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                    } else if line.hasPrefix("URL:") {
                        let urlString = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                        url = urlString == "none" ? nil : urlString
                    }
                }
                
                guard !title.isEmpty, !description.isEmpty, !action.isEmpty else {
                    return nil
                }
                
                return AISuggestion(
                    title: title,
                    description: description,
                    type: type,
                    priority: priority,
                    actionText: action,
                    actionURL: url
                )
            }
        
        return Array(suggestions.prefix(6)) // Limit to 6 suggestions
    }
    
    // MARK: - Generate Quick Problem Set
    func generateQuickProblemSet(
        userRating: Int,
        weakTopic: String?,
        count: Int = 5
    ) -> [String] {
        let baseRating = max(800, userRating - 200)
        let maxRating = userRating + 300
        
        var urls: [String] = []
        
        if let topic = weakTopic {
            // Topic-specific problem set
            urls.append("https://codeforces.com/problemset?tags=\(topic)&order=BY_RATING_ASC")
        }
        
        // General practice based on rating
        urls.append("https://codeforces.com/problemset?order=BY_RATING_ASC")
        
        // Recent contest problems
        urls.append("https://codeforces.com/contests")
        
        return urls
    }
    
    // MARK: - Generate Problem Recommendations
    func generateProblemRecommendations(
        submissions: [CFSubmission],
        user: CFUser?,
        targetCount: Int = 5
    ) async -> [ProblemRecommendation] {
        let userRating = user?.rating ?? 1200
        let acceptedSubmissions = submissions.filter { $0.isAccepted }
        
        // Analyze what topics user needs to work on
        let weakTopics = identifyWeakTopics(acceptedSubmissions: acceptedSubmissions)
        let optimalRatingRange = (userRating - 100)...(userRating + 200)
        
        var recommendations: [ProblemRecommendation] = []
        
        // Recommend problems for weak topics
        for topic in weakTopics.prefix(3) {
            let recommendation = ProblemRecommendation(
                title: "Master \(topic.capitalized)",
                difficulty: "Rating \(userRating - 50) - \(userRating + 150)",
                topic: topic,
                reason: "You've solved only \(getTopicCount(topic: topic, submissions: acceptedSubmissions)) problems in this area",
                codeforcesURL: "https://codeforces.com/problemset?tags=\(topic.replacingOccurrences(of: " ", with: "%20"))&order=BY_RATING_ASC",
                priority: .high
            )
            recommendations.append(recommendation)
        }
        
        // Add difficulty progression recommendation
        let avgSolvedRating = acceptedSubmissions.compactMap { ($0.problem.rating ?? 0) > 0 ? $0.problem.rating : nil }
            .reduce(0, +) / max(acceptedSubmissions.count, 1)
        
        if avgSolvedRating < userRating - 100 {
            let recommendation = ProblemRecommendation(
                title: "Challenge Yourself",
                difficulty: "Rating \(userRating) - \(userRating + 200)",
                topic: "mixed",
                reason: "Your recent problems are too easy. Time to level up!",
                codeforcesURL: "https://codeforces.com/problemset?order=BY_RATING_ASC",
                priority: .high
            )
            recommendations.append(recommendation)
        }
        
        return Array(recommendations.prefix(targetCount))
    }
    
    private func identifyWeakTopics(acceptedSubmissions: [CFSubmission]) -> [String] {
        let allTags = acceptedSubmissions.flatMap { $0.problem.tags }
        let tagCounts = Dictionary(grouping: allTags) { $0 }.mapValues { $0.count }
        
        let essentialTopics = [
            "implementation", "math", "greedy", "dp", "graphs", "data structures",
            "binary search", "two pointers", "sorting", "strings", "brute force"
        ]
        
        return essentialTopics.filter { topic in
            let count = tagCounts[topic] ?? 0
            return count < 5 // Consider weak if less than 5 problems solved
        }
    }
    
    private func getTopicCount(topic: String, submissions: [CFSubmission]) -> Int {
        return submissions.filter { submission in
            submission.problem.tags.contains { $0.lowercased() == topic.lowercased() }
        }.count
    }
}

// MARK: - User Stats Helper
struct UserStats {
    let totalSubmissions: Int
    let acceptedSubmissions: Int
    let acceptanceRate: Double
    let mostUsedLanguage: String
    let currentStreak: Int
    let weeklySubmissions: Int
    let topTopics: [String]
    let recentPerformance: String
}


