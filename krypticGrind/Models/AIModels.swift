//
//  AIModels.swift
//  KrypticGrind
//
//  Created by akhil on 15/07/25.
//

import Foundation

// MARK: - AI Suggestion Model
struct AISuggestion: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let type: SuggestionType
    let priority: Priority
    let actionText: String
    let actionURL: String?
    
    enum SuggestionType: String, Codable, CaseIterable {
        case practice = "Practice"
        case improvement = "Improvement"
        case topic = "Topic"
        case contest = "Contest"
        case streak = "Streak"
        
        var color: String {
            switch self {
            case .practice: return "blue"
            case .improvement: return "orange"
            case .topic: return "purple"
            case .contest: return "red"
            case .streak: return "green"
            }
        }
        
        var icon: String {
            switch self {
            case .practice: return "target"
            case .improvement: return "arrow.up.circle"
            case .topic: return "book.circle"
            case .contest: return "trophy.circle"
            case .streak: return "flame.circle"
            }
        }
        
        var displayText: String {
            return self.rawValue
        }
    }
    
    enum Priority: String, Codable, CaseIterable {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var displayText: String {
            return self.rawValue
        }
    }
}

// MARK: - User Stats Model
struct UserStats: Codable {
    let totalSubmissions: Int
    let acceptedSubmissions: Int
    let acceptanceRate: Double
    let mostUsedLanguage: String
    let currentStreak: Int
    let weeklySubmissions: Int
    let topTopics: [String]
    let recentPerformance: String
}

// MARK: - Contest Analytics Model
struct ContestAnalytics: Codable {
    let totalContests: Int
    let averageRank: Double
    let bestRank: Int
    let ratingChanges: [Int]
    let participationRate: Double
    let strongTopics: [String]
    let weakTopics: [String]
}

// MARK: - Problem Difficulty Model
struct ProblemDifficulty: Codable {
    let rating: Int
    let solvedCount: Int
    let attemptedCount: Int
    let successRate: Double
}
