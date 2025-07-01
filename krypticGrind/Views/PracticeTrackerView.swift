//
//  PracticeTrackerView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI
import Charts

struct PracticeTrackerView: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedAnalysis: AnalysisType = .tags
    
    enum AnalysisType: String, CaseIterable {
        case tags = "Tags"
        case languages = "Languages"
        case verdicts = "Verdicts"
        case difficulty = "Difficulty"
        
        var systemImage: String {
            switch self {
            case .tags: return "tag"
            case .languages: return "chevron.left.forwardslash.chevron.right"
            case .verdicts: return "checkmark.circle"
            case .difficulty: return "chart.bar"
            }
        }
        
        var color: Color {
            switch self {
            case .tags: return .purple
            case .languages: return .green
            case .verdicts: return .blue
            case .difficulty: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Analysis Type Selector
                AnalysisSelector(selectedAnalysis: $selectedAnalysis)
                    .padding()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Main Chart
                        AnalysisChart(analysisType: selectedAnalysis)
                        
                        // Statistics Cards
                        PracticeStatsGrid()
                        
                        // Recommendations
                        if selectedAnalysis == .tags {
                            RecommendationsCard()
                        }
                        
                        // Review Later Card
                        ReviewLaterPreviewCard()
                        
                        // Topic Progression
                        TopicProgressionCard()
                        
                        // Progress Insights
                        ProgressInsightsCard()
                    }
                    .padding()
                }
            }
            .background(themeManager.colors.background)
            .navigationTitle("Practice Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchUserSubmissions(handle: handle, count: 200)
            }
        }
    }
}

struct AnalysisSelector: View {
    @Binding var selectedAnalysis: PracticeTrackerView.AnalysisType
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PracticeTrackerView.AnalysisType.allCases, id: \.self) { type in
                    AnalysisTab(
                        type: type,
                        isSelected: selectedAnalysis == type
                    ) {
                        selectedAnalysis = type
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct AnalysisTab: View {
    let type: PracticeTrackerView.AnalysisType
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.subheadline)
                
                Text(type.rawValue)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    isSelected ? AnyShapeStyle(type.color) : AnyShapeStyle(.ultraThinMaterial)
            )
            )

            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct AnalysisChart: View {
    let analysisType: PracticeTrackerView.AnalysisType
    @StateObject private var cfService = CFService.shared
    
    var chartData: [(String, Int)] {
        switch analysisType {
        case .tags:
            return Array(cfService.getTagStatistics()
                .sorted { $0.value > $1.value }
                .prefix(10))
        case .languages:
            return Array(cfService.getLanguageStatistics()
                .sorted { $0.value > $1.value }
                .prefix(8))
        case .verdicts:
            return Array(cfService.getVerdictStatistics()
                .sorted { $0.value > $1.value })
        case .difficulty:
            return getDifficultyStatistics()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("\(analysisType.rawValue) Analysis", systemImage: analysisType.systemImage)
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            if chartData.isEmpty {
                EmptyChartView(analysisType: analysisType)
            } else {
                switch analysisType {
                case .tags, .languages:
                    HorizontalBarChart(data: chartData)
                case .verdicts:
                    PieChartView(data: chartData)
                case .difficulty:
                    VerticalBarChart(data: chartData)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func getDifficultyStatistics() -> [(String, Int)] {
        var difficultyCounts: [String: Int] = [:]
        
        for submission in cfService.recentSubmissions where submission.isAccepted {
            let difficulty = submission.problem.difficulty
            difficultyCounts[difficulty, default: 0] += 1
        }
        
        let difficultyOrder = ["Unrated", "Beginner", "Easy", "Medium", "Hard", "Expert"]
        return difficultyOrder.compactMap { difficulty in
            guard let count = difficultyCounts[difficulty], count > 0 else { return nil }
            return (difficulty, count)
        }
    }
}

struct HorizontalBarChart: View {
    let data: [(String, Int)]
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \ .offset) { index, item in
                BarMark(
                    x: .value("Count", item.1),
                    y: .value("Category", item.0)
                )
                .foregroundStyle(Color.accentColor)
                .cornerRadius(4)
            }
        }
        .frame(height: max(200, CGFloat(data.count * 25)))
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(.gray)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(.primary)
            }
        }
    }
}

struct VerticalBarChart: View {
    let data: [(String, Int)]
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \ .offset) { index, item in
                BarMark(
                    x: .value("Category", item.0),
                    y: .value("Count", item.1)
                )
                .foregroundStyle(Color.accentColor)
                .cornerRadius(4)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(.primary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(.gray)
            }
        }
    }
}

struct PieChartView: View {
    let data: [(String, Int)]
    
    var body: some View {
        VStack(spacing: 16) {
            // Simple pie chart representation using progress circles
            VStack(spacing: 12) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    PieSliceRow(
                        label: item.0,
                        value: item.1,
                        total: data.reduce(0) { $0 + $1.1 },
                        color: pieColor(for: index)
                    )
                }
            }
        }
    }
    
    private func pieColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .red, .yellow, .pink, .cyan, .purple]
        return colors[index % colors.count]
    }
}

struct PieSliceRow: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color
    
    var percentage: Double {
        Double(value) / Double(total) * 100
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(value)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text("(\(Int(percentage))%)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: percentage / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 60)
        }
    }
}

struct EmptyChartView: View {
    let analysisType: PracticeTrackerView.AnalysisType
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: analysisType.systemImage)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No data available")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Submit some problems to see \(analysisType.rawValue.lowercased()) analysis")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

struct PracticeStatsGrid: View {
    @StateObject private var cfService = CFService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Practice Statistics", systemImage: "chart.bar.fill")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PracticeStatCard(
                    title: "Total Submissions",
                    value: "\(cfService.recentSubmissions.count)",
                    icon: "doc.text",
                    color: .blue
                )
                
                PracticeStatCard(
                    title: "Accepted",
                    value: "\(cfService.recentSubmissions.acceptedSubmissions().count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                let acceptanceRate = cfService.recentSubmissions.isEmpty ? 0 : 
                    (Double(cfService.recentSubmissions.acceptedSubmissions().count) / Double(cfService.recentSubmissions.count) * 100)
                
                PracticeStatCard(
                    title: "Acceptance Rate",
                    value: "\(Int(acceptanceRate))%",
                    icon: "percent",
                    color: acceptanceRate >= 50 ? .green : .orange
                )
                
                PracticeStatCard(
                    title: "Unique Problems",
                    value: "\(Set(cfService.recentSubmissions.map { $0.problem.name }).count)",
                    icon: "puzzlepiece",
                    color: .purple
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PracticeStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct RecommendationsCard: View {
    @StateObject private var cfService = CFService.shared
    @State private var geminiSuggestion: String? = nil
    @State private var isLoadingGemini = false
    @State private var geminiError: String? = nil
    @State private var lastHandle: String? = UserDefaults.standard.savedHandle
    @Namespace private var animation
    @State private var isFetchingProblems = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("Recommendations", systemImage: "lightbulb.fill")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            // Gemini suggestion section
            Group {
                if isLoadingGemini || isFetchingProblems {
                    ProgressView(isFetchingProblems ? "Fetching recent problems..." : "Fetching AI suggestion...")
                        .font(.caption)
                } else if let error = geminiError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                } else if let suggestion = geminiSuggestion, !suggestion.isEmpty {
                    Button(action: { /* TODO: Hook up action */ }) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkle")
                                .foregroundColor(.accentColor)
                            Text(suggestion)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(10)
                        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .matchedGeometryEffect(id: "geminiSuggestion", in: animation)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: geminiSuggestion)
                }
            }

            Divider().padding(.vertical, 2)

            let tagStats = cfService.getTagStatistics()
            let totalSolved = tagStats.values.reduce(0, +)
            
            if totalSolved == 0 {
                Text("Start solving problems to get personalized recommendations!")
                    .font(.body)
                    .foregroundColor(.gray)
            } else {
                let weakTags = getTopWeakTags(tagStats: tagStats, limit: 2)
                
                if weakTags.isEmpty {
                    Text("Great work! You're well-balanced across different topics.")
                        .font(.body)
                        .foregroundColor(.green)
                } else {
                    Text("Consider practicing these topics:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)

                    FlexibleTagGrid(tags: weakTags, animation: animation)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: weakTags)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            fetchAndSuggest()
        }
        .onChange(of: UserDefaults.standard.savedHandle) { newHandle in
            if lastHandle != newHandle {
                lastHandle = newHandle
                geminiSuggestion = nil
                fetchAndSuggest()
            }
        }
    }

    private func fetchAndSuggest() {
        guard !isLoadingGemini && geminiSuggestion == nil else { return }
        isFetchingProblems = true
        geminiError = nil
        Task {
            // Always fetch latest submissions before suggesting
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchUserSubmissions(handle: handle, count: 20)
                        }
            isFetchingProblems = false
            isLoadingGemini = true
            let problemsSummary = cfService.recentProblemsSummary(count: 10)
            GeminiService.shared.getPersonalizedPracticeSuggestion(problemsSummary: problemsSummary) { result in
                DispatchQueue.main.async {
                    isLoadingGemini = false
                    switch result {
                    case .success(let suggestion):
                        withAnimation {
                            geminiSuggestion = suggestion
                        }
                    case .failure:
                        geminiError = "Could not fetch AI suggestion."
                    }
                }
            }
        }
    }
    
    private func getTopWeakTags(tagStats: [String: Int], limit: Int) -> [String] {
        let commonTags = ["implementation", "math", "greedy", "dp", "graphs", "strings", "sorting", "binary search"]
        let avgCount = tagStats.values.reduce(0, +) / max(tagStats.count, 1)
        let weakTags = commonTags.filter { tag in
            (tagStats[tag] ?? 0) < avgCount / 2
        }
        .sorted { (tagStats[$0] ?? 0) < (tagStats[$1] ?? 0) }
        return Array(weakTags.prefix(limit))
    }
}

struct FlexibleTagGrid: View {
    let tags: [String]
    var animation: Namespace.ID? = nil
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Button(action: { /* TODO: Hook up tag action */ }) {
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.18), in: Capsule())
                        .foregroundColor(.orange)
                        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                        .scaleEffect(0.98)
                        .matchedGeometryEffect(id: tag, in: animation ?? Namespace().wrappedValue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ProgressInsightsCard: View {
    @StateObject private var cfService = CFService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Progress Insights", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                InsightRow(
                    title: "Most Used Language",
                    value: getMostUsedLanguage(),
                    icon: "chevron.left.forwardslash.chevron.right"
                )
                
                InsightRow(
                    title: "Favorite Topic",
                    value: getFavoriteTopic(),
                    icon: "heart"
                )
                
                InsightRow(
                    title: "Current Streak",
                    value: getCurrentStreak(),
                    icon: "flame"
                )
                
                InsightRow(
                    title: "This Week",
                    value: getThisWeekSubmissions(),
                    icon: "calendar.circle"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func getMostUsedLanguage() -> String {
        let langStats = cfService.getLanguageStatistics()
        return langStats.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    private func getFavoriteTopic() -> String {
        let tagStats = cfService.getTagStatistics()
        return tagStats.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    private func getCurrentStreak() -> String {
        // Simple streak calculation - consecutive days with at least one submission
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for _ in 0..<30 { // Check last 30 days
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let hasSubmission = cfService.recentSubmissions.contains { submission in
                let submissionDate = calendar.startOfDay(for: submission.submissionDate)
                return submissionDate >= currentDate && submissionDate < nextDate
            }
            
            if hasSubmission {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return "\(streak) days"
    }
    
    private func getThisWeekSubmissions() -> String {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        
        let thisWeekSubmissions = cfService.recentSubmissions.filter { submission in
            submission.submissionDate >= weekAgo
        }
        
        return "\(thisWeekSubmissions.count) submissions"
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}

struct ReviewLaterPreviewCard: View {
    @StateObject private var problemDataManager = ProblemDataManager.shared
    @StateObject private var cfService = CFService.shared
    @State private var showingReviewLaterView = false
    
    var reviewLaterCount: Int {
        problemDataManager.getReviewLaterProblems().count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Review Later", systemImage: "bookmark")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if reviewLaterCount > 0 {
                    Text("\(reviewLaterCount)")
                        .font(.headline.bold())
                        .foregroundStyle(.orange)
                }
            }
            
            if reviewLaterCount == 0 {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange.opacity(0.6))
                    
                    VStack(spacing: 4) {
                        Text("No Problems to Review")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        
                        Text("Mark problems from your submissions to review them later")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    // Show up to 3 recent review later problems
                    ForEach(Array(problemDataManager.getReviewLaterProblems().prefix(3)), id: \.id) { reviewLater in
                        if let submission = cfService.recentSubmissions.first(where: { $0.problem.problemId == reviewLater.problemId }) {
                            ReviewLaterPreviewRow(submission: submission, reviewLater: reviewLater)
                        }
                    }
                    
                    if reviewLaterCount > 3 {
                        Text("+ \(reviewLaterCount - 3) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Button(action: {
                showingReviewLaterView = true
            }) {
                HStack {
                    Text(reviewLaterCount > 0 ? "View All" : "Start Reviewing")
                        .font(.subheadline.weight(.medium))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingReviewLaterView) {
            ReviewLaterView()
        }
    }
}

struct ReviewLaterPreviewRow: View {
    let submission: CFSubmission
    let reviewLater: ProblemReviewLater
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Problem info
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.problem.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(submission.problem.index)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(.blue)
                    
                    if let rating = submission.problem.rating {
                        Text("\(rating)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.ratingColor(for: rating).opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                            .foregroundStyle(Color.ratingColor(for: rating))
                    }
                    
                    Text(submission.verdictDisplayText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.verdictColor(for: submission.verdict ?? ""))
                }
            }
            
            Spacer()
            
            // Bookmark icon
            Image(systemName: "bookmark.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct TopicProgressionCard: View {
    @StateObject private var cfService = CFService.shared
    @State private var showingAllTopics = false
    
    var topTopics: [(String, Int)] {
        Array(cfService.getTagStatistics()
            .sorted { $0.value > $1.value }
            .prefix(6))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Topic Progression", systemImage: "chart.bar.fill")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !topTopics.isEmpty {
                    Button("View All") {
                        showingAllTopics = true
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.blue)
                }
            }
            
            if topTopics.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue.opacity(0.6))
                    
                    VStack(spacing: 4) {
                        Text("No Topic Data")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        
                        Text("Solve more problems to see your topic progression")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(topTopics, id: \.0) { topic, count in
                        TopicProgressRow(topic: topic, count: count, maxCount: topTopics.first?.1 ?? 1)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingAllTopics) {
            TopicProgressionView()
        }
    }
}

struct TopicProgressRow: View {
    let topic: String
    let count: Int
    let maxCount: Int
    @StateObject private var themeManager = ThemeManager.shared
    
    private var progress: Double {
        guard maxCount > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }
    
    private var progressColor: Color {
        if progress >= 0.8 { return .green }
        else if progress >= 0.5 { return .orange }
        else { return .blue }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(topic.capitalized())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(progressColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor.gradient)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

struct TopicProgressionView: View {
    @StateObject private var cfService = CFService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredTopics: [(String, Int)] {
        let allTopics = Array(cfService.getTagStatistics()
            .sorted { $0.value > $1.value })
        
        if searchText.isEmpty {
            return allTopics
        }
        
        return allTopics.filter { topic, _ in
            topic.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(searchText: $searchText)
                        .padding()
                    
                    if filteredTopics.isEmpty {
                        EmptyTopicProgressionView(searchText: searchText)
                    } else {
                        TopicProgressionList(topics: filteredTopics)
                    }
                }
            }
            .navigationTitle("Topic Progression")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.colors.accent)
                }
            }
        }
        .task {
            if let handle = UserDefaults.standard.savedHandle {
                await cfService.fetchUserSubmissions(handle: handle, count: 200)
            }
        }
    }
}

struct TopicProgressionList: View {
    let topics: [(String, Int)]
    @StateObject private var themeManager = ThemeManager.shared
    
    var maxCount: Int {
        topics.first?.1 ?? 1
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(topics, id: \.0) { topic, count in
                    TopicProgressionDetailCard(topic: topic, count: count, maxCount: maxCount)
                }
            }
            .padding()
        }
    }
}

struct TopicProgressionDetailCard: View {
    let topic: String
    let count: Int
    let maxCount: Int
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var cfService = CFService.shared
    
    private var progress: Double {
        guard maxCount > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }
    
    private var progressColor: Color {
        if progress >= 0.8 { return .green }
        else if progress >= 0.5 { return .orange }
        else { return .blue }
    }
    
    private var problemsInTopic: [CFSubmission] {
        cfService.recentSubmissions.filter { submission in
            submission.isAccepted && submission.problem.tags.contains(topic)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.capitalized())
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                    
                    Text("\(count) problems solved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(progressColor)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor.gradient)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
            
            // Recent problems in this topic
            if !problemsInTopic.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Problems")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    ForEach(Array(problemsInTopic.prefix(3)), id: \.id) { submission in
                        HStack {
                            Text(submission.problem.name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let rating = submission.problem.rating {
                                Text("\(rating)")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.ratingColor(for: rating).opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                                    .foregroundStyle(Color.ratingColor(for: rating))
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct EmptyTopicProgressionView: View {
    let searchText: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 8) {
                    Text(emptyTitle)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            if searchText.isEmpty {
                Button("Start Practicing") {
                    if let url = URL(string: "https://codeforces.com/problemset") {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyTitle: String {
        if searchText.isEmpty {
            return "No Topic Data"
        } else {
            return "No Matching Topics"
        }
    }
    
    private var emptyMessage: String {
        if searchText.isEmpty {
            return "Solve more problems to see your topic progression and identify your strengths and weaknesses."
        } else {
            return "No topics match your search. Try different keywords or clear the search."
        }
    }
}

// MARK: - Reusable SearchBar
struct SearchBar: View {
    @Binding var searchText: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            
            TextField("Search topics...", text: $searchText)
                .foregroundStyle(.primary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationView {
        PracticeTrackerView()
    }
}
