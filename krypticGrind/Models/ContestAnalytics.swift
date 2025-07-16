//
//  ContestAnalytics.swift
//  KrypticGrind
//
//  Created by akhil on 14/07/25.
//

import Foundation

// MARK: - Contest Standings
struct CFContestStandings: Codable {
    let status: String
    let result: ContestStandingsResult
}

struct ContestStandingsResult: Codable {
    let contest: CFContest
    let problems: [ContestProblem]
    let rows: [StandingRow]
}

struct ContestProblem: Codable, Identifiable {
    let contestId: Int?
    let index: String
    let name: String
    let type: String
    let rating: Int?
    let tags: [String]
    
    var id: String {
        "\(contestId ?? 0)-\(index)"
    }
}

struct StandingRow: Codable, Identifiable {
    let party: Party
    let rank: Int
    let points: Double
    let penalty: Int
    let successfulHackCount: Int
    let unsuccessfulHackCount: Int
    let problemResults: [ProblemResult]
    
    var id: String {
        party.members.first?.handle ?? "\(rank)"
    }
}

struct Party: Codable {
    let contestId: Int?
    let members: [Member]
    let participantType: String
    let ghost: Bool
    let room: Int?
    let startTimeSeconds: Int?
}

struct Member: Codable {
    let handle: String
    let name: String?
}

struct ProblemResult: Codable {
    let points: Double
    let penalty: Int?
    let rejectedAttemptCount: Int
    let type: String
    let bestSubmissionTimeSeconds: Int?
}

// MARK: - Contest Status (Submissions)
struct CFContestStatus: Codable {
    let status: String
    let result: [ContestSubmission]
}

struct ContestSubmission: Codable, Identifiable {
    let id: Int
    let contestId: Int?
    let creationTimeSeconds: Int
    let relativeTimeSeconds: Int
    let problem: ContestProblem
    let author: Party
    let programmingLanguage: String
    let verdict: String?
    let testset: String
    let passedTestCount: Int
    let timeConsumedMillis: Int
    let memoryConsumedBytes: Int
    
    var submissionDate: Date {
        Date(timeIntervalSince1970: TimeInterval(creationTimeSeconds))
    }
    
    var verdictDisplayText: String {
        switch verdict {
        case "OK": return "Accepted"
        case "WRONG_ANSWER": return "Wrong Answer"
        case "TIME_LIMIT_EXCEEDED": return "Time Limit"
        case "MEMORY_LIMIT_EXCEEDED": return "Memory Limit"
        case "RUNTIME_ERROR": return "Runtime Error"
        case "COMPILATION_ERROR": return "Compilation Error"
        case "PRESENTATION_ERROR": return "Presentation Error"
        case "IDLENESS_LIMIT_EXCEEDED": return "Idleness Limit"
        case "SECURITY_VIOLATED": return "Security Violated"
        case "CRASHED": return "Crashed"
        case "INPUT_PREPARATION_CRASHED": return "Input Crashed"
        case "CHALLENGED": return "Challenged"
        case "SKIPPED": return "Skipped"
        case "TESTING": return "Testing"
        case "REJECTED": return "Rejected"
        default: return verdict ?? "Unknown"
        }
    }
}

// MARK: - Rating Changes
struct CFRatingChanges: Codable {
    let status: String
    let result: [RatingChange]
}

struct RatingChange: Codable, Identifiable {
    let contestId: Int
    let contestName: String
    let handle: String
    let rank: Int
    let ratingUpdateTimeSeconds: Int
    let oldRating: Int
    let newRating: Int
    
    var id: String {
        "\(contestId)-\(handle)"
    }
    
    var ratingChange: Int {
        newRating - oldRating
    }
    
    var updateDate: Date {
        Date(timeIntervalSince1970: TimeInterval(ratingUpdateTimeSeconds))
    }
}

// MARK: - Contest Analytics Service
@MainActor
class ContestAnalyticsService: ObservableObject {
    static let shared = ContestAnalyticsService()
    
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    func fetchContestStandings(contestId: Int) async -> ContestStandingsResult? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URL(string: "https://codeforces.com/api/contest.standings?contestId=\(contestId)&from=1&count=10")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CFContestStandings.self, from: data)
            
            if response.status == "OK" {
                error = nil
                return response.result
            } else {
                error = "Failed to fetch standings"
                return nil
            }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
            return nil
        }
    }
    
    func fetchContestSubmissions(contestId: Int, handle: String? = nil) async -> [ContestSubmission] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var urlString = "https://codeforces.com/api/contest.status?contestId=\(contestId)&from=1&count=50"
            if let handle = handle {
                urlString += "&handle=\(handle)"
            }
            
            let url = URL(string: urlString)!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CFContestStatus.self, from: data)
            
            if response.status == "OK" {
                error = nil
                return response.result
            } else {
                error = "Failed to fetch submissions"
                return []
            }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
            return []
        }
    }
    
    func fetchRatingChanges(contestId: Int) async -> [RatingChange] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URL(string: "https://codeforces.com/api/contest.ratingChanges?contestId=\(contestId)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CFRatingChanges.self, from: data)
            
            if response.status == "OK" {
                error = nil
                return response.result
            } else {
                error = "Failed to fetch rating changes"
                return []
            }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
            return []
        }
    }
}
