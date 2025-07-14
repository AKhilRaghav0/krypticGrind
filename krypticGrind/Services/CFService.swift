//
//  CFService.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import Foundation
import Combine
import os.log
import Network

// MARK: - Network Monitor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - API Service for Codeforces
class CFService: ObservableObject {
    static let shared = CFService()
    
    private let baseURL = "https://codeforces.com/api"
    private let alternativeURLs = [
        "https://codeforces.com/api",
        "https://codeforces.ml/api", // Alternative mirror (if available)
        "https://cf.likianta.com/api" // Another potential mirror
    ]
    
    // Background queue for network operations
    private let backgroundQueue = DispatchQueue(label: "com.krypticgrind.cfservice", qos: .userInitiated)
    private let session: URLSession
    private let logger = Logger(subsystem: "com.akhilraghav.krypticGrind", category: "CFService")
    private let networkMonitor = NetworkMonitor.shared
    
    // Published properties for reactive UI
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUser: CFUser?
    @Published var ratingHistory: [CFRatingChange] = []
    @Published var recentSubmissions: [CFSubmission] = []
    @Published var upcomingContests: [CFContest] = []
    @Published var problems: [CFProblem] = []
    
    // Computed property for next contest
    var nextContest: CFContest? {
        return upcomingContests.first
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Configure URLSession for background operations
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        // Monitor network changes
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if !isConnected {
                    self?.error = "No internet connection detected"
                } else if self?.error?.contains("No internet") == true {
                    self?.error = nil
                }
            }
            .store(in: &cancellables)
    }
    
    /// Fetches user information for the specified Codeforces handle and updates the current user state.
    /// - Parameter handle: The Codeforces user handle to look up.
    /// 
    /// Initiates a network request to retrieve user details. Updates loading and error states on the main thread. If the user is found, updates the current user and saves the handle to persistent storage. Sets an error message if the user is not found or if a network error occurs.
    func fetchUserInfo(handle: String) async {
        logger.info("🔍 Fetching user info for handle: \(handle)")
        
        // Update UI on main thread
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Perform network request on background queue
            let apiResponse = try await performAPIRequest(
                url: "\(baseURL)/user.info?handles=\(handle)",
                responseType: CFUserResponse.self
            )
            
            logger.info("✅ API Response Status: \(apiResponse.status)")
            
            // Update UI on main thread
            await MainActor.run {
                if apiResponse.status == "OK", let user = apiResponse.result.first {
                    currentUser = user
                    UserDefaults.standard.set(handle, forKey: "saved_handle")
                    logger.info("🎉 Successfully fetched user: \(user.handle) (Rating: \(user.rating))")
                } else {
                    let errorMsg = apiResponse.status == "FAILED" ? "User '\(handle)' not found" : "API returned error status: \(apiResponse.status)"
                    logger.error("❌ \(errorMsg)")
                    error = errorMsg
                }
            }
        } catch {
            let errorMsg = "Failed to fetch user info: \(error.localizedDescription)"
            logger.error("💥 \(errorMsg)")
            
            // Update UI on main thread
            await MainActor.run {
                if error.localizedDescription.contains("not found") || error.localizedDescription.contains("404") {
                    self.error = "User '\(handle)' not found. Please check the handle."
                } else {
                    self.error = "Network error. Please check your connection and try again."
                }
            }
        }
        
        // Update loading state on main thread
        await MainActor.run {
            isLoading = false
        }
    }
    
    /// Fetches and updates the user's rating history from the Codeforces API asynchronously.
    /// - Parameter handle: The Codeforces user handle whose rating history is to be retrieved.
    /// 
    /// On success, updates the `ratingHistory` property with the user's rating changes sorted by update time. On failure, sets an error message.
    func fetchRatingHistory(handle: String) async {
        logger.info("📈 Fetching rating history for: \(handle)")
        
        do {
            let url = URL(string: "\(baseURL)/user.rating?handle=\(handle)")!
            logger.debug("📡 Rating API Request: \(url.absoluteString)")
            
            // Perform network request on background queue
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.info("📊 Rating HTTP Status: \(httpResponse.statusCode)")
            }
            
            let apiResponse = try JSONDecoder().decode(CFRatingResponse.self, from: data)
            logger.info("✅ Rating API Status: \(apiResponse.status)")
            
            // Update UI on main thread
            await MainActor.run {
                if apiResponse.status == "OK" {
                    self.ratingHistory = apiResponse.result.sorted { $0.ratingUpdateTimeSeconds < $1.ratingUpdateTimeSeconds }
                    logger.info("📈 Loaded \(self.ratingHistory.count) rating changes")
                } else {
                    logger.warning("⚠️ Rating API returned non-OK status")
                }
            }
        } catch {
            let errorMsg = "Failed to fetch rating history: \(error.localizedDescription)"
            logger.error("💥 \(errorMsg)")
            
            // Update UI on main thread
            await MainActor.run {
                self.error = errorMsg
            }
        }
    }
    
    /// Fetches a user's recent submissions from the Codeforces API and updates the published property with the results.
    /// - Parameters:
    ///   - handle: The Codeforces user handle.
    ///   - count: The number of recent submissions to fetch (default is 50).
    ///
    /// On success, updates `recentSubmissions` with the most recent submissions sorted by creation time. On failure, sets an error message.
    func fetchUserSubmissions(handle: String, count: Int = 50) async {
        logger.info("📝 Fetching \(count) submissions for: \(handle)")
        
        do {
            let url = URL(string: "\(baseURL)/user.status?handle=\(handle)&from=1&count=\(count)")!
            logger.debug("📡 Submissions API Request: \(url.absoluteString)")
            
            // Perform network request on background queue
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.info("📊 Submissions HTTP Status: \(httpResponse.statusCode)")
            }
            
            let apiResponse = try JSONDecoder().decode(CFSubmissionsResponse.self, from: data)
            logger.info("✅ Submissions API Status: \(apiResponse.status)")
            
            // Update UI on main thread
            await MainActor.run {
                if apiResponse.status == "OK" {
                    self.recentSubmissions = apiResponse.result.sorted { $0.creationTimeSeconds > $1.creationTimeSeconds }
                    logger.info("📝 Loaded \(self.recentSubmissions.count) submissions")
                } else {
                    logger.warning("⚠️ Submissions API returned non-OK status")
                }
            }
        } catch {
            let errorMsg = "Failed to fetch submissions: \(error.localizedDescription)"
            logger.error("💥 \(errorMsg)")
            
            // Update UI on main thread
            await MainActor.run {
                self.error = errorMsg
            }
        }
    }
    
    /// Fetches the list of upcoming Codeforces contests and updates the published property.
    /// - Note: On success, updates and caches up to 10 upcoming contests. If the API call fails or returns an error status, attempts to load cached contest data. Sets an appropriate error message for various failure scenarios.
    func fetchContests() async {
        logger.info("🏆 Fetching contests list")
        
        // Update UI on main thread
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Try the standard API first with more robust retry logic
            let apiResponse = try await performAPIRequest(
                url: "\(baseURL)/contest.list",
                responseType: CFContestResponse.self,
                retries: 3
            )
            
            // Update UI on main thread
            await MainActor.run {
                if apiResponse.status == "OK" {
                    let upcoming = apiResponse.result
                        .filter { $0.isUpcoming }
                        .sorted { 
                            guard let start1 = $0.startTimeSeconds, let start2 = $1.startTimeSeconds else { 
                                return false 
                            }
                            return start1 < start2 
                        }
                        .prefix(10)
                        .map { $0 }
                    
                    self.upcomingContests = upcoming
                    logger.info("🏆 Loaded \(self.upcomingContests.count) upcoming contests")
                    
                    // Cache successful result
                    if let encoded = try? JSONEncoder().encode(upcoming) {
                        UserDefaults.standard.set(encoded, forKey: "cached_contests")
                        UserDefaults.standard.set(Date(), forKey: "contests_cache_time")
                    }
                } else {
                    logger.warning("⚠️ Contests API returned status: \(apiResponse.status)")
                    Task {
                        await loadCachedContestsIfAvailable()
                    }
                    self.error = "Contests API returned error status. Showing cached data if available."
                }
            }
        } catch {
            let errorMsg = "Failed to fetch contests: \(error.localizedDescription)"
            logger.error("💥 Contest fetch error: \(errorMsg)")
            
            // Try to load cached data first
            await loadCachedContestsIfAvailable()
            
            // Update UI on main thread
            await MainActor.run {
                // More specific error handling
                if errorMsg.contains("cancelled") {
                    logger.error("🚫 Request was cancelled - possibly due to timeout or network issue")
                    self.error = "Network request cancelled. Tap to retry or check your internet connection."
                } else if errorMsg.contains("timeout") {
                    logger.error("⏰ Request timed out")
                    self.error = "Request timed out. Codeforces servers might be slow. Tap to retry."
                } else if (error as? URLError)?.code == .notConnectedToInternet {
                    self.error = "No internet connection. Please check your network and tap to retry."
                } else if (error as? URLError)?.code == .cannotConnectToHost {
                    self.error = "Cannot connect to Codeforces. Server might be down. Tap to retry."
                } else {
                    self.error = "Unable to fetch contests. Tap to retry or check later."
                }
            }
        }
        
        // Update loading state on main thread
        await MainActor.run {
            isLoading = false
        }
    }
    
    /// Loads upcoming contests from cache if available and not older than 24 hours.
    /// Updates the `upcomingContests` property on the main actor if valid cached data is found.
    private func loadCachedContestsIfAvailable() async {
        logger.info("📦 Attempting to load cached contests")
        
        guard let cachedData = UserDefaults.standard.data(forKey: "cached_contests"),
              let cachedTime = UserDefaults.standard.object(forKey: "contests_cache_time") as? Date else {
            logger.info("📦 No cached contests found")
            return
        }
        
        // Check if cache is not too old (24 hours)
        let cacheAge = Date().timeIntervalSince(cachedTime)
        guard cacheAge < 24 * 60 * 60 else {
            logger.info("📦 Cached contests too old (\(cacheAge/3600) hours)")
            return
        }
        
        do {
            let cachedContests = try JSONDecoder().decode([CFContest].self, from: cachedData)
            
            // Update UI on main thread
            await MainActor.run {
                self.upcomingContests = cachedContests.filter { $0.isUpcoming }
                logger.info("📦 Loaded \(self.upcomingContests.count) cached contests from \(cachedTime)")
            }
        } catch {
            logger.error("📦 Failed to decode cached contests: \(error)")
        }
    }
    
    /// Fetches the complete list of problems from the Codeforces API and updates the published problems property.
    /// Updates the error property if the request fails.
    func fetchProblems() async {
        do {
            let url = URL(string: "\(baseURL)/problemset.problems")!
            
            // Perform network request on background queue
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(CFProblemsetResponse.self, from: data)
            
            // Update UI on main thread
            await MainActor.run {
                if response.status == "OK" {
                    problems = response.result.problems
                }
            }
        } catch {
            // Update UI on main thread
            await MainActor.run {
                self.error = "Failed to fetch problems: \(error.localizedDescription)"
            }
        }
    }
    
    /// Fetches all user-related data from the Codeforces API for the given handle, including user info, rating history, recent submissions, and upcoming contests.
    /// - Parameter handle: The Codeforces user handle to fetch data for.
    /// 
    /// Initiates user info retrieval first; if the user exists, concurrently fetches rating history, submissions (up to 100), and contests. Updates loading state on the main thread before and after the operation.
    func fetchAllUserData(handle: String) async {
        // Update loading state on main thread
        await MainActor.run {
            isLoading = true
        }
        
        // First fetch user info
        await fetchUserInfo(handle: handle)
        
        // If user exists, fetch all other data concurrently
        if currentUser != nil {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { 
                    await self.fetchRatingHistory(handle: handle) 
                }
                group.addTask { 
                    await self.fetchUserSubmissions(handle: handle, count: 100) 
                }
                group.addTask { 
                    await self.fetchContests() 
                }
            }
        }
        
        // Update loading state on main thread
        await MainActor.run {
            isLoading = false
        }
    }
    
    /// Refreshes all user-related data using the saved handle from user defaults.
    /// 
    /// If a handle is stored, concurrently fetches user info, rating history, submissions, and upcoming contests.
    func refreshData() async {
        guard let handle = UserDefaults.standard.string(forKey: "saved_handle") else { return }
        
        // Use the optimized concurrent method
        await fetchAllUserData(handle: handle)
    }
    
    // MARK: - Practice Analytics
    func getTagStatistics() -> [String: Int] {
        var tagCounts: [String: Int] = [:]
        
        for submission in recentSubmissions where submission.isAccepted {
            for tag in submission.problem.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts
    }
    
    func getLanguageStatistics() -> [String: Int] {
        var langCounts: [String: Int] = [:]
        
        for submission in recentSubmissions {
            langCounts[submission.programmingLanguage, default: 0] += 1
        }
        
        return langCounts
    }
    
    /// Returns a dictionary mapping verdict display texts to their occurrence counts in recent submissions.
    func getVerdictStatistics() -> [String: Int] {
        var verdictCounts: [String: Int] = [:]
        
        for submission in recentSubmissions {
            let verdict = submission.verdictDisplayText
            verdictCounts[verdict, default: 0] += 1
        }
        
        return verdictCounts
    }
    
    /// Asynchronously computes the count of accepted submissions for each problem tag.
    /// - Returns: A dictionary mapping each tag to the number of accepted submissions with that tag.
    func getTagStatisticsAsync() async -> [String: Int] {
        return await Task.detached(priority: .userInitiated) {
            var tagCounts: [String: Int] = [:]
            
            for submission in self.recentSubmissions where submission.isAccepted {
                for tag in submission.problem.tags {
                    tagCounts[tag, default: 0] += 1
                }
            }
            
            return tagCounts
        }.value
    }
    
    /// Asynchronously computes the count of each programming language used in recent submissions.
    /// - Returns: A dictionary mapping programming language names to their usage counts.
    func getLanguageStatisticsAsync() async -> [String: Int] {
        return await Task.detached(priority: .userInitiated) {
            var langCounts: [String: Int] = [:]
            
            for submission in self.recentSubmissions {
                langCounts[submission.programmingLanguage, default: 0] += 1
            }
            
            return langCounts
        }.value
    }
    
    /// Asynchronously computes the count of each verdict type from recent submissions.
    /// - Returns: A dictionary mapping verdict display texts to their occurrence counts.
    func getVerdictStatisticsAsync() async -> [String: Int] {
        return await Task.detached(priority: .userInitiated) {
            var verdictCounts: [String: Int] = [:]
            
            for submission in self.recentSubmissions {
                let verdict = submission.verdictDisplayText
                verdictCounts[verdict, default: 0] += 1
            }
            
            return verdictCounts
        }.value
    }
    
    /// Asynchronously computes the count of accepted submissions for each problem difficulty.
    /// - Returns: A dictionary mapping problem difficulty levels to the number of accepted submissions for each.
    func getDifficultyStatisticsAsync() async -> [String: Int] {
        return await Task.detached(priority: .userInitiated) {
            var difficultyCounts: [String: Int] = [:]
            
            for submission in self.recentSubmissions where submission.isAccepted {
                let difficulty = submission.problem.difficulty
                difficultyCounts[difficulty, default: 0] += 1
            }
            
            return difficultyCounts
        }.value
    }
    
    /// Returns the number of submissions made today based on the user's recent submissions.
    func getTodaysSubmissionCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return recentSubmissions.filter { submission in
            let submissionDate = submission.submissionDate
            return submissionDate >= today && submissionDate < tomorrow
        }.count
    }
    
    func getTodaysAcceptedCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return recentSubmissions.filter { submission in
            let submissionDate = submission.submissionDate
            return submission.isAccepted && submissionDate >= today && submissionDate < tomorrow
        }.count
    }
    
    func recentProblemsSummary(count: Int = 10) -> String {
        let recent = Array(recentSubmissions.prefix(count))
        var summary = "Recent problems:\n"
        for (i, sub) in recent.enumerated() {
            let tags = sub.problem.tags.joined(separator: ", ")
            let verdict = sub.verdict
            summary += "\(i+1). \(sub.problem.name) (tags: \(tags)) - \(verdict)\n"
        }
        return summary
    }
    
    // MARK: - Fetch Submission Source Code
    func fetchSubmissionSourceCode(submissionId: Int) async -> String? {
        logger.info("📄 Fetching source code for submission: \(submissionId)")
        
        do {
            let url = URL(string: "https://codeforces.com/contest/\(submissionId)/submission/\(submissionId)")!
            logger.debug("📡 Source code URL: \(url.absoluteString)")
            
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.info("📊 Source code HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    if let htmlString = String(data: data, encoding: .utf8) {
                        // Extract source code from HTML
                        return extractSourceCodeFromHTML(htmlString)
                    }
                }
            }
        } catch {
            logger.error("💥 Failed to fetch source code: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func extractSourceCodeFromHTML(_ html: String) -> String? {
        // Simple extraction - look for <pre> tags containing code
        let pattern = #"<pre[^>]*>(.*?)</pre>"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range) {
                if let range = Range(match.range(at: 1), in: html) {
                    let code = String(html[range])
                    // Decode HTML entities
                    return code.replacingOccurrences(of: "&lt;", with: "<")
                               .replacingOccurrences(of: "&gt;", with: ">")
                               .replacingOccurrences(of: "&amp;", with: "&")
                               .replacingOccurrences(of: "&quot;", with: "\"")
                               .replacingOccurrences(of: "&#39;", with: "'")
                }
            }
        }
        
        return nil
    }
}

// MARK: - Error Handling & Retry
extension CFService {
    func clearError() {
        error = nil
    }
    
    func retryLastOperation() async {
        logger.info("🔄 User initiated retry")
        clearError()
        
        // Try to fetch contests again (most common failure point)
        await fetchContests()
    }
}

// MARK: - Helper Methods
extension CFService {
    /// Performs an HTTP GET request to the specified URL, attempting multiple base URLs and retrying on failure with exponential backoff.
    /// - Parameters:
    ///   - url: The endpoint URL string to request.
    ///   - responseType: The expected Codable type for decoding the JSON response.
    ///   - retries: The number of retry attempts per base URL (default is 3).
    /// - Returns: The decoded response object of the specified type.
    /// - Throws: An error if all attempts fail, if the network is unavailable, or if the response cannot be decoded.
    private func performAPIRequest<T: Codable>(
        url: String,
        responseType: T.Type,
        retries: Int = 3
    ) async throws -> T {
        // Check network connectivity first
        guard networkMonitor.isConnected else {
            throw URLError(.notConnectedToInternet)
        }
        
        var lastError: Error?
        
        // Try multiple base URLs if available
        let urlsToTry = alternativeURLs.map { baseUrl in
            url.replacingOccurrences(of: baseURL, with: baseUrl)
        }
        
        for baseUrl in urlsToTry {
            logger.info("🌐 Trying base URL: \(baseUrl)")
            
            for attempt in 1...(retries + 1) {
                do {
                    logger.debug("🔄 Attempt \(attempt)/\(retries + 1) for: \(baseUrl)")
                    
                    guard let requestURL = URL(string: baseUrl) else {
                        throw URLError(.badURL)
                    }
                    
                    // Create request with headers and longer timeout
                    var request = URLRequest(url: requestURL)
                    request.setValue("KrypticGrind/1.0", forHTTPHeaderField: "User-Agent")
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
                    request.timeoutInterval = 45.0 // Increased timeout
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    
                    // Use custom URLSession with better configuration for this request
                    let config = URLSessionConfiguration.default
                    config.timeoutIntervalForRequest = 45.0
                    config.timeoutIntervalForResource = 60.0
                    config.waitsForConnectivity = true
                    config.allowsCellularAccess = true
                    config.allowsExpensiveNetworkAccess = true
                    config.allowsConstrainedNetworkAccess = true
                    let customSession = URLSession(configuration: config)
                    
                    let startTime = Date()
                    let (data, response) = try await customSession.data(for: request)
                    let requestTime = Date().timeIntervalSince(startTime)
                    
                    logger.info("⏱️ Request completed in \(String(format: "%.2f", requestTime))s")
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        logger.info("📊 HTTP \(httpResponse.statusCode) for: \(baseUrl)")
                        
                        if httpResponse.statusCode == 429 {
                            // Rate limited - wait before retry
                            logger.warning("🚦 Rate limited, waiting 3 seconds...")
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            continue
                        }
                        
                        if httpResponse.statusCode >= 500 {
                            // Server error - retry
                            logger.warning("🚨 Server error \(httpResponse.statusCode), retrying...")
                            if attempt < retries + 1 {
                                let delay = UInt64(attempt) * 2_000_000_000 // 2s, 4s, 6s...
                                try await Task.sleep(nanoseconds: delay)
                                continue
                            }
                        }
                        
                        if httpResponse.statusCode >= 400 {
                            throw URLError(.badServerResponse)
                        }
                    }
                    
                    // Log response data size for debugging
                    logger.debug("📦 Received \(data.count) bytes")
                    
                    // Try to decode the response
                    do {
                        let result = try JSONDecoder().decode(responseType, from: data)
                        logger.info("✅ Successfully decoded response for: \(baseUrl)")
                        customSession.invalidateAndCancel()
                        return result
                    } catch let decodingError {
                        logger.error("🔍 JSON Decoding Error: \(decodingError)")
                        // Log the response data for debugging
                        if let responseString = String(data: data, encoding: .utf8) {
                            logger.debug("📄 Response data: \(responseString.prefix(500))")
                        }
                        throw decodingError
                    }
                    
                } catch {
                    lastError = error
                    logger.warning("⚠️ Attempt \(attempt) failed for \(baseUrl): \(error.localizedDescription)")
                    
                    // For cancelled errors, wait a bit longer before retry
                    if error.localizedDescription.contains("cancelled") && attempt < retries + 1 {
                        logger.info("🔄 Request cancelled, waiting 5 seconds before retry...")
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                    } else if attempt < retries + 1 {
                        // Standard exponential backoff
                        let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000 // 1s, 2s, 4s...
                        try await Task.sleep(nanoseconds: delay)
                    }
                }
            }
            
            // If all attempts failed for this URL, try the next URL
            logger.warning("❌ All attempts failed for \(baseUrl), trying next URL...")
        }
        
        throw lastError ?? URLError(.unknown)
    }
}

// MARK: - Background Data Processing
extension CFService {
    /// Processes a list of submissions in parallel by chunking and sorting them by creation time in descending order.
    /// - Parameter submissions: The array of submissions to process.
    /// - Returns: A new array of submissions sorted by creation time, with processing performed concurrently for improved performance.
    private func processSubmissionsData(_ submissions: [CFSubmission]) async -> [CFSubmission] {
        return await withTaskGroup(of: [CFSubmission].self) { group in
            // Split submissions into chunks for parallel processing
            let chunkSize = max(1, submissions.count / 4)
            let chunks = submissions.chunked(into: chunkSize)
            
            for chunk in chunks {
                group.addTask {
                    // Perform any heavy processing on background queue
                    return chunk.sorted { $0.creationTimeSeconds > $1.creationTimeSeconds }
                }
            }
            
            var result: [CFSubmission] = []
            for await processedChunk in group {
                result.append(contentsOf: processedChunk)
            }
            
            return result.sorted { $0.creationTimeSeconds > $1.creationTimeSeconds }
        }
    }
}

// MARK: - Memory Management
extension CFService {
    /// Clears all cached data and resets published properties to their initial state on the main actor.
    func clearCache() {
        Task { @MainActor in
            recentSubmissions.removeAll()
            ratingHistory.removeAll()
            upcomingContests.removeAll()
            problems.removeAll()
            currentUser = nil
            error = nil
        }
    }
}
