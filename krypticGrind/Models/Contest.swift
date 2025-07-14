//
//  Contest.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import Foundation
import SwiftUI

// MARK: - Contest List Response
struct CFContestResponse: Codable {
    let status: String
    let result: [CFContest]
}

struct CFContest: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let phase: String
    let frozen: Bool
    let durationSeconds: Int
    let startTimeSeconds: Int?
    let relativeTimeSeconds: Int?
    let preparedBy: String?
    let websiteUrl: String?
    let description: String?
    let difficulty: Int?
    let kind: String?
    let icpcRegion: String?
    let country: String?
    let city: String?
    let season: String?
    
    // Computed properties
    var startDate: Date? {
        guard let startTimeSeconds = startTimeSeconds else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(startTimeSeconds))
    }
    
    var endDate: Date? {
        guard let startDate = startDate else { return nil }
        return startDate.addingTimeInterval(TimeInterval(durationSeconds))
    }
    
    var isUpcoming: Bool {
        phase == "BEFORE"
    }
    
    var isRunning: Bool {
        phase == "CODING"
    }
    
    var isFinished: Bool {
        phase == "FINISHED"
    }
    
    var duration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var timeUntilStart: String? {
        guard let startDate = startDate, isUpcoming else { return nil }
        let now = Date()
        let timeInterval = startDate.timeIntervalSince(now)
        
        if timeInterval <= 0 { return "Starting now" }
        
        let days = Int(timeInterval) / 86400
        let hours = (Int(timeInterval) % 86400) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var contestUrl: String {
        "https://codeforces.com/contest/\(id)"
    }
    
    var registrationUrl: String {
        "https://codeforces.com/contest/\(id)/register"
    }
    
    var standingsUrl: String {
        "https://codeforces.com/contest/\(id)/standings"
    }
    
    var problemsUrl: String {
        "https://codeforces.com/contest/\(id)"
    }
    
    var announcementsUrl: String {
        "https://codeforces.com/contest/\(id)/blog"
    }
    
    var phaseColor: String {
        switch phase {
        case "BEFORE": return "blue"
        case "CODING": return "green"
        case "PENDING_SYSTEM_TEST": return "orange"
        case "SYSTEM_TEST": return "orange"
        case "FINISHED": return "gray"
        default: return "gray"
        }
    }
    
    var phaseColorValue: Color {
        switch phase {
        case "BEFORE": return .blue
        case "CODING": return .green
        case "PENDING_SYSTEM_TEST": return .orange
        case "SYSTEM_TEST": return .orange
        case "FINISHED": return .gray
        default: return .gray
        }
    }
    
    var phaseDisplayText: String {
        switch phase {
        case "BEFORE": return "Upcoming"
        case "CODING": return "Running"
        case "PENDING_SYSTEM_TEST": return "Pending Tests"
        case "SYSTEM_TEST": return "System Test"
        case "FINISHED": return "Finished"
        default: return phase
        }
    }
    
    var statusEmoji: String {
        switch phase {
        case "BEFORE": return "🕐"
        case "CODING": return "⚡"
        case "PENDING_SYSTEM_TEST": return "⏳"
        case "SYSTEM_TEST": return "🔄"
        case "FINISHED": return "🏁"
        default: return "❓"
        }
    }
    
    var difficultyText: String {
        guard let difficulty = difficulty else { return "Unknown" }
        switch difficulty {
        case 1: return "Beginner"
        case 2: return "Easy"
        case 3: return "Medium"
        case 4: return "Hard"
        case 5: return "Expert"
        default: return "Level \(difficulty)"
        }
    }
    
    var typeDisplayText: String {
        switch type.lowercased() {
        case "cf": return "Codeforces Round"
        case "ioi": return "IOI Style"
        case "icpc": return "ICPC Style"
        default: return type.capitalized
        }
    }
    
    var estimatedProblems: Int {
        // Estimate number of problems based on duration and type
        let hours = durationSeconds / 3600
        switch type.lowercased() {
        case "cf":
            if hours <= 2 { return 5 }
            else if hours <= 3 { return 6 }
            else { return 7 }
        case "ioi": return 3
        case "icpc": return 10
        default: return hours // Rough estimate
        }
    }
    
    var ratingImpact: String {
        switch phase {
        case "FINISHED": return "Rated"
        case "CODING", "PENDING_SYSTEM_TEST", "SYSTEM_TEST": return "Will be rated"
        case "BEFORE": return type.lowercased() == "cf" ? "Will be rated" : "Check rules"
        default: return "TBD"
        }
    }
}

// MARK: - Problemset Response
struct CFProblemsetResponse: Codable {
    let status: String
    let result: CFProblemsetResult
}

struct CFProblemsetResult: Codable {
    let problems: [CFProblem]
    let problemStatistics: [CFProblemStatistic]
}

struct CFProblemStatistic: Codable {
    let contestId: Int?
    let index: String
    let solvedCount: Int
}

// MARK: - Contest Standings Response
struct CFContestStandingsResponse: Codable {
    let status: String
    let result: CFContestStandingsResult
}

struct CFContestStandingsResult: Codable {
    let contest: CFContest
    let problems: [CFProblem]
    let rows: [CFRanklistRow]
}

struct CFRanklistRow: Codable {
    let party: CFParty
    let rank: Int
    let points: Double
    let penalty: Int
    let successfulHackCount: Int
    let unsuccessfulHackCount: Int
    let problemResults: [CFProblemResult]
}

struct CFParty: Codable {
    let contestId: Int?
    let members: [CFMember]
    let participantType: String
    let teamId: Int?
    let teamName: String?
    let ghost: Bool
    let room: Int?
    let startTimeSeconds: Int?
}

struct CFMember: Codable {
    let handle: String
    let name: String?
}

struct CFProblemResult: Codable {
    let points: Double
    let penalty: Int?
    let rejectedAttemptCount: Int
    let type: String
    let bestSubmissionTimeSeconds: Int?
}
