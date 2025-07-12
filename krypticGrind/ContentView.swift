//
//  ContentView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    var body: some View {
        TabView {
            NavigationView {
                FontTestView()
            }
            .tabItem {
                Label("Test", systemImage: "textformat")
            }
            
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            RatingChartView()
                .tabItem {
                    Label("Rating", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            SubmissionsView()
                .tabItem {
                    Label("Submissions", systemImage: "doc.text.fill")
                }
            
            ContestListView()
                .tabItem {
                    Label("Contests", systemImage: "trophy.fill")
                }
            
            PracticeTrackerView()
                .tabItem {
                    Label("Practice", systemImage: "target")
                }
            
            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy")
                }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .tint(themeManager.colors.accent)
    }
}

#Preview {
    ContentView()
}
