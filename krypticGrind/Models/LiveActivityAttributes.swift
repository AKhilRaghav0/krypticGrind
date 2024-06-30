import Foundation
import ActivityKit

// #if canImport(ActivityKit)
// import ActivityKit
// #endif

#if canImport(ActivityKit)
struct ContestCountdownAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
    }
    var contestName: String
}
#endif 