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
        }
        .preferredColorScheme(themeManager.colorScheme)
        .tint(themeManager.colors.accent)
    }
}

#Preview {
    ContentView()
}
