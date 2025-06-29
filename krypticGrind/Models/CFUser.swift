//
//  CFUser.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import Foundation

// MARK: - User Info Response
struct CFUserResponse: Codable {
    let status: String
    let result: [CFUser]
}

struct CFUser: Codable, Identifiable {
    var id: UUID { UUID() }
    let handle: String
    let email: String?
    let vkId: String?
    let openId: String?
    let firstName: String?
    let lastName: String?
    let country: String?
    let city: String?
    let organization: String?
    let contribution: Int
    let rank: String
    let rating: Int
    let maxRank: String
    let maxRating: Int
    let lastOnlineTimeSeconds: Int
    let registrationTimeSeconds: Int
    let friendOfCount: Int
    let avatar: String
    let titlePhoto: String
    
    private enum CodingKeys: String, CodingKey {
        case handle, email, vkId, openId, firstName, lastName
        case country, city, organization, contribution, rank, rating
        case maxRank, maxRating, lastOnlineTimeSeconds, registrationTimeSeconds
        case friendOfCount, avatar, titlePhoto
    }
    
    // Computed properties for better UX
    var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        }
        return handle
    }
    
    var ratingColor: String {
        switch rating {
        case 1200..<1400: return "green"
        case 1400..<1600: return "cyan"
        case 1600..<1900: return "blue"
        case 1900..<2100: return "purple"
        case 2100..<2300: return "orange"
        case 2300..<2400: return "red"
        case 2400...: return "red"
        default: return "gray"
        }
    }
    
    var lastOnlineDate: Date {
        Date(timeIntervalSince1970: TimeInterval(lastOnlineTimeSeconds))
    }
    
    var registrationDate: Date {
        Date(timeIntervalSince1970: TimeInterval(registrationTimeSeconds))
    }
}

// MARK: - Rating History
struct CFRatingResponse: Codable {
    let status: String
    let result: [CFRatingChange]
}

struct CFRatingChange: Codable, Identifiable {
    var id: UUID { UUID() }
    let contestId: Int
    let contestName: String
    let handle: String
    let rank: Int
    let ratingUpdateTimeSeconds: Int
    let oldRating: Int
    let newRating: Int
    
    // Computed properties
    var delta: Int {
        newRating - oldRating
    }
    
    var updateDate: Date {
        Date(timeIntervalSince1970: TimeInterval(ratingUpdateTimeSeconds))
    }
    
    var deltaString: String {
        delta > 0 ? "+\(delta)" : "\(delta)"
    }
}
