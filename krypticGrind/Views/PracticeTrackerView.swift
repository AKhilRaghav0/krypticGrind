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
                isSelected ? type.color.gradient : themeManager.colors.surface.gradient,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                BarMark(
                    x: .value("Count", item.1),
                    y: .value("Category", item.0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
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
                    .foregroundStyle(.white)
            }
        }
    }
}

struct VerticalBarChart: View {
    let data: [(String, Int)]
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                BarMark(
                    x: .value("Category", item.0),
                    y: .value("Count", item.1)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(.white)
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
        let colors: [Color] = [.blue, .purple, .green, .orange, .red, .yellow, .pink, .cyan]
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct RecommendationsCard: View {
    @StateObject private var cfService = CFService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Recommendations", systemImage: "lightbulb.fill")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            let tagStats = cfService.getTagStatistics()
            let totalSolved = tagStats.values.reduce(0, +)
            
            if totalSolved == 0 {
                Text("Start solving problems to get personalized recommendations!")
                    .font(.body)
                    .foregroundColor(.gray)
            } else {
                let weakTags = getWeakTags(tagStats: tagStats)
                
                if weakTags.isEmpty {
                    Text("Great work! You're well-balanced across different topics.")
                        .font(.body)
                        .foregroundColor(.green)
                } else {
                    Text("Consider practicing these topics:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100))
                    ], spacing: 8) {
                        ForEach(weakTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func getWeakTags(tagStats: [String: Int]) -> [String] {
        let commonTags = ["implementation", "math", "greedy", "dp", "graphs", "strings", "sorting", "binary search"]
        let avgCount = tagStats.values.reduce(0, +) / max(tagStats.count, 1)
        
        return commonTags.filter { tag in
            (tagStats[tag] ?? 0) < avgCount / 2
        }.prefix(6).map { $0 }
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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

#Preview {
    NavigationView {
        PracticeTrackerView()
    }
}
