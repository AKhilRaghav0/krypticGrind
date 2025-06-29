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
