//
//  UpcomingContestsWidget.swift
//  ContestLiveActivityWidget
//
//  Created by akhil on 29/06/25.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Contest Model
struct WidgetContest: Codable, Identifiable {
    let id: Int
    let name: String
    let startTimeSeconds: TimeInterval?
    let durationSeconds: Int
    
    var isUpcoming: Bool {
        guard let startTime = startTimeSeconds else { return false }
        return startTime > Date().timeIntervalSince1970
    }
}

struct WidgetContestResponse: Codable {
    let status: String
    let result: [WidgetContest]
}

struct UpcomingContestsWidget: Widget {
    let kind: String = "UpcomingContestsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingContestsProvider()) { entry in
            UpcomingContestsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming Contests")
        .description("Shows your next Codeforces contests")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct UpcomingContestsProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingContestsEntry {
        UpcomingContestsEntry(date: Date(), contests: [
            WidgetContest(id: 1, name: "Codeforces Round #123", startTimeSeconds: Date().timeIntervalSince1970 + 3600, durationSeconds: 7200)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingContestsEntry) -> ()) {
        let entry = UpcomingContestsEntry(date: Date(), contests: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let contests = await fetchUpcomingContests()
            let entry = UpcomingContestsEntry(date: Date(), contests: contests)
            
            // Update every hour
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    private func fetchUpcomingContests() async -> [WidgetContest] {
        do {
            let url = URL(string: "https://codeforces.com/api/contest.list")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let response = try JSONDecoder().decode(WidgetContestResponse.self, from: data)
            
            if response.status == "OK" {
                return response.result
                    .filter { $0.isUpcoming }
                    .sorted { 
                        guard let start1 = $0.startTimeSeconds, let start2 = $1.startTimeSeconds else { 
                            return false 
                        }
                        return start1 < start2 
                    }
                    .prefix(3)
                    .map { $0 }
            }
        } catch {
            print("Failed to fetch contests: \(error)")
        }
        
        return []
    }
}

struct UpcomingContestsEntry: TimelineEntry {
    let date: Date
    let contests: [WidgetContest]
}

struct UpcomingContestsWidgetEntryView: View {
    var entry: UpcomingContestsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallUpcomingContestsView(entry: entry)
        case .systemMedium:
            MediumUpcomingContestsView(entry: entry)
        default:
            SmallUpcomingContestsView(entry: entry)
        }
    }
}

struct SmallUpcomingContestsView: View {
    let entry: UpcomingContestsEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.orange)
                Text("Contests")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            if entry.contests.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("No upcoming contests")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if let nextContest = entry.contests.first {
                        Text(nextContest.name)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        if let startTime = nextContest.startTimeSeconds {
                            let timeUntil = Date(timeIntervalSince1970: startTime).timeIntervalSince(Date())
                            Text(timeUntil > 0 ? "In \(formatTimeInterval(timeUntil))" : "Starting now")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = Int(interval) % 86400 / 3600
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else {
            return "\(hours)h"
        }
    }
}

struct MediumUpcomingContestsView: View {
    let entry: UpcomingContestsEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.orange)
                Text("Upcoming Contests")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            if entry.contests.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("No upcoming contests")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 6) {
                    ForEach(entry.contests.prefix(3), id: \.id) { contest in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contest.name)
                                    .font(.caption.bold())
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                
                                if let startTime = contest.startTimeSeconds {
                                    let timeUntil = Date(timeIntervalSince1970: startTime).timeIntervalSince(Date())
                                    Text(timeUntil > 0 ? "In \(formatTimeInterval(timeUntil))" : "Starting now")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = Int(interval) % 86400 / 3600
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else {
            return "\(hours)h"
        }
    }
}

#Preview(as: .systemSmall) {
    UpcomingContestsWidget()
} timeline: {
    UpcomingContestsEntry(date: Date(), contests: [])
}

#Preview(as: .systemMedium) {
    UpcomingContestsWidget()
} timeline: {
    UpcomingContestsEntry(date: Date(), contests: [])
} 