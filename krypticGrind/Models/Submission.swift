//
//  Submission.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import Foundation

// MARK: - User Submissions Response
struct CFSubmissionsResponse: Codable {
    let status: String
    let result: [CFSubmission]
}

struct CFSubmission: Codable, Identifiable, Equatable {
    var id: Int { creationTimeSeconds }
    let contestId: Int?
    let creationTimeSeconds: Int
    let relativeTimeSeconds: Int
    let problem: CFProblem
    let author: CFParty
    let programmingLanguage: String
    let verdict: String?
    let testset: String
    let passedTestCount: Int
    let timeConsumedMillis: Int
    let memoryConsumedBytes: Int
    
    /// Determines whether two `CFSubmission` instances are equal based on creation time, contest ID, and problem ID.
    /// - Parameters:
    ///   - lhs: The first submission to compare.
    ///   - rhs: The second submission to compare.
    /// - Returns: `true` if both submissions have the same creation time, contest ID, and problem ID; otherwise, `false`.
    static func == (lhs: CFSubmission, rhs: CFSubmission) -> Bool {
        return lhs.creationTimeSeconds == rhs.creationTimeSeconds &&
               lhs.contestId == rhs.contestId &&
               lhs.problem.problemId == rhs.problem.problemId
    }
    
    // Computed properties
    var submissionDate: Date {
        Date(timeIntervalSince1970: TimeInterval(creationTimeSeconds))
    }
    
    var isAccepted: Bool {
        verdict == "OK"
    }
    
    var verdictColor: String {
        switch verdict {
        case "OK": return "green"
        case "WRONG_ANSWER": return "red"
        case "TIME_LIMIT_EXCEEDED": return "orange"
        case "MEMORY_LIMIT_EXCEEDED": return "orange"
        case "RUNTIME_ERROR": return "purple"
        case "COMPILATION_ERROR": return "gray"
        default: return "blue"
        }
    }
    
    var verdictDisplayText: String {
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
        default: return verdict ?? "UNKNOWN"
        }
    }
}

struct CFProblem: Codable, Equatable {
    let contestId: Int?
    let problemsetName: String?
    let index: String
    let name: String
    let type: String
    let points: Double?
    let rating: Int?
    let tags: [String]
    
    // Computed properties
    var difficulty: String {
        guard let rating = rating else { return "Unrated" }
        switch rating {
        case ..<1200: return "Beginner"
        case 1200..<1600: return "Easy"
        case 1600..<2000: return "Medium"
        case 2000..<2400: return "Hard"
        case 2400...: return "Expert"
        default: return "Unrated"
        }
    }
    
    var problemUrl: String {
        if let contestId = contestId {
            return "https://codeforces.com/contest/\(contestId)/problem/\(index)"
        }
        return "https://codeforces.com/problemset/problem/\(index)"
    }
}

struct CFParty: Codable, Equatable {
    let contestId: Int?
    let members: [CFMember]
    let participantType: String
    let teamId: Int?
    let teamName: String?
    let ghost: Bool
    let room: Int?
    let startTimeSeconds: Int?
}

struct CFMember: Codable, Equatable {
    let handle: String
    let name: String?
}
