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
    @AppStorage("appearance_mode") private var appearanceMode: String = "system"
    
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
        .preferredColorScheme(colorScheme)
        .tint(themeManager.colors.accent)
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }
}

#Preview {
    ContentView()
}
