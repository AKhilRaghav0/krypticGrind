// Depends on MainTab and CustomTabBar from Views/CustomTabBar.swift
import SwiftUI
import Charts

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .rating:
                    RatingChartView()
                case .submissions:
                    SubmissionsView()
                case .home:
                    HomeView()
                case .contests:
                    ContestListView()
                case .practice:
                    PracticeTrackerView() // You can merge Leaderboard here if needed
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.lightLavender.ignoresSafeArea())

            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 8)
        }
        .preferredColorScheme(themeManager.colorScheme)
        .tint(themeManager.colors.accent)
    }
}

#Preview {
    ContentView()
}
