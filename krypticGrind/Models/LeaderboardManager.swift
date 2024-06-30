//
//  LeaderboardManager.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import Foundation

// MARK: - Leaderboard Handle
struct LeaderboardHandle: Codable, Identifiable {
    let id = UUID()
    let handle: String
    let firstName: String?
    let lastName: String?
    let rating: Int
    let maxRating: Int
    let rank: String?
    let problemsSolved: Int
    let contestsParticipated: Int
    let ratingChange: Int
    let lastUpdated: Date
    
    init(handle: String, firstName: String? = nil, lastName: String? = nil, rating: Int = 0, maxRating: Int = 0, rank: String? = nil, problemsSolved: Int = 0, contestsParticipated: Int = 0, ratingChange: Int = 0) {
        self.handle = handle
        self.firstName = firstName
        self.lastName = lastName
        self.rating = rating
        self.maxRating = maxRating
        self.rank = rank
        self.problemsSolved = problemsSolved
        self.contestsParticipated = contestsParticipated
        self.ratingChange = ratingChange
        self.lastUpdated = Date()
    }
}

// MARK: - Leaderboard Error
enum LeaderboardError: Error, LocalizedError {
    case alreadyExists
    case notFoundOrInvalid
    
    var errorDescription: String? {
        switch self {
        case .alreadyExists:
            return "Handle already exists in leaderboard"
        case .notFoundOrInvalid:
            return "Handle not found or invalid"
        }
    }
}

// MARK: - Leaderboard Manager
@MainActor
class LeaderboardManager: ObservableObject {
    static let shared = LeaderboardManager()
    
    @Published var handles: [LeaderboardHandle] = []
    
    private let handlesKey = "leaderboard_handles"
    private let cfService = CFService.shared
    
    private init() {
        loadHandles()
    }
    
    // MARK: - Handle Management
    func addHandle(_ handle: String) async -> Result<Void, LeaderboardError> {
        // Check if handle already exists
        if handles.contains(where: { $0.handle.lowercased() == handle.lowercased() }) {
            return .failure(.alreadyExists)
        }
        
        // Verify handle exists on Codeforces
        do {
            let userInfo = try await fetchUserInfo(handle: handle)
            let newHandle = LeaderboardHandle(
                handle: handle,
                firstName: userInfo.firstName,
                lastName: userInfo.lastName,
                rating: userInfo.rating,
                maxRating: userInfo.maxRating,
                rank: userInfo.rank,
                problemsSolved: userInfo.problemsSolved,
                contestsParticipated: userInfo.contestsParticipated,
                ratingChange: 0
            )
            
            handles.append(newHandle)
            saveHandles()
            return .success(())
        } catch {
            return .failure(.notFoundOrInvalid)
        }
    }
    
    func removeHandle(_ handle: LeaderboardHandle) {
        handles.removeAll { $0.id == handle.id }
        saveHandles()
    }
    
    func refreshHandle(_ handle: LeaderboardHandle) async {
        do {
            let userInfo = try await fetchUserInfo(handle: handle.handle)
            let oldRating = handle.rating
            
            if let index = handles.firstIndex(where: { $0.id == handle.id }) {
                let updatedHandle = LeaderboardHandle(
                    handle: handle.handle,
                    firstName: userInfo.firstName,
                    lastName: userInfo.lastName,
                    rating: userInfo.rating,
                    maxRating: userInfo.maxRating,
                    rank: userInfo.rank,
                    problemsSolved: userInfo.problemsSolved,
                    contestsParticipated: userInfo.contestsParticipated,
                    ratingChange: userInfo.rating - oldRating
                )
                
                handles[index] = updatedHandle
                saveHandles()
            }
        } catch {
            print("Failed to refresh handle: \(error)")
        }
    }
    
    func refreshAllHandles() async {
        for handle in handles {
            await refreshHandle(handle)
        }
    }
    
    // MARK: - API Calls
    private func fetchUserInfo(handle: String) async throws -> CFUser {
        let url = URL(string: "https://codeforces.com/api/user.info?handles=\(handle)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(CFUserResponse.self, from: data)
        
        if response.status == "OK", let user = response.result.first {
            return user
        } else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Persistence
    private func saveHandles() {
        if let encoded = try? JSONEncoder().encode(handles) {
            UserDefaults.standard.set(encoded, forKey: handlesKey)
        }
    }
    
    private func loadHandles() {
        if let handlesData = UserDefaults.standard.data(forKey: handlesKey),
           let decodedHandles = try? JSONDecoder().decode([LeaderboardHandle].self, from: handlesData) {
            handles = decodedHandles
        }
    }
}

// MARK: - Extensions
extension CFUser {
    var problemsSolved: Int {
        // This is a placeholder - Codeforces API doesn't provide this directly
        // You could calculate this from submissions, but that's expensive
        return 0
    }
    
    var contestsParticipated: Int {
        // This is a placeholder - Codeforces API doesn't provide this directly
        // You could calculate this from rating history, but that's expensive
        return 0
    }
} 