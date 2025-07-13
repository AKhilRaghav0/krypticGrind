// Depends on MainTab and CustomTabBar from Views/CustomTabBar.swift
import SwiftUI
import Charts

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @EnvironmentObject var colorThemeManager: ColorThemeManager

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
                    PracticeAndLeaderboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorThemeManager.current.background.ignoresSafeArea())
            .animation(.easeInOut, value: colorThemeManager.current)

            CustomTabBar(selectedTab: $selectedTab)
                .environmentObject(colorThemeManager)
                .padding(.bottom, 0.02)

            // Floating color palette button
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            colorThemeManager.nextTheme()
                        }
                    }) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(colorThemeManager.current.accent)
                            .padding(20)
                            .background(colorThemeManager.current.tabBar.opacity(0.95))
                            .clipShape(Circle())
                            .shadow(color: colorThemeManager.current.accent.opacity(0.18), radius: 8, y: 2)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 100)
                }
            }
            .allowsHitTesting(true)
        }
        .tint(colorThemeManager.current.accent)
    }
}

// Merged Practice/Leaderboard tab
struct PracticeAndLeaderboardView: View {
    @State private var selected: Int = 0
    var body: some View {
        VStack {
            Picker("Mode", selection: $selected) {
                Text("Practice").tag(0)
                Text("Leaderboard").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selected == 0 {
                PracticeTrackerView()
            } else {
                LeaderboardView()
            }
        }
    }
}

#Preview {
    ContentView()
}
