// Depends on MainTab and CustomTabBar from Views/CustomTabBar.swift
import SwiftUI
import Charts

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch") == false ? true : false
    @EnvironmentObject var colorThemeManager: ColorThemeManager

    var body: some View {
        ZStack {
            if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
                    .environmentObject(colorThemeManager)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 1.1))
                    ))
            } else {
                mainAppView
            }
        }
        .onAppear {
            // Set default value for first launch if not set
            if UserDefaults.standard.object(forKey: "isFirstLaunch") == nil {
                UserDefaults.standard.set(true, forKey: "isFirstLaunch")
                isFirstLaunch = true
            }
        }
    }
    
    private var mainAppView: some View {
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
    @State private var selectedTab: DungeonTab = .practice
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    enum DungeonTab: String, CaseIterable {
        case practice = "Training Grounds"
        case leaderboard = "Hall of Fame"
        
        var icon: String {
            switch self {
            case .practice: return "⚔️"
            case .leaderboard: return "👑"
            }
        }
        
        var dungeonTitle: String {
            switch self {
            case .practice: return "Training Grounds"
            case .leaderboard: return "Hall of Fame"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Dungeon Header
                    DungeonHeader(selectedTab: $selectedTab)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        DungeonPracticeView()
                            .tag(DungeonTab.practice)
                        
                        DungeonLeaderboardView()
                            .tag(DungeonTab.leaderboard)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(colorThemeManager.current.accent)
    }
}

// MARK: - Dungeon Header
struct DungeonHeader: View {
    @Binding var selectedTab: PracticeAndLeaderboardView.DungeonTab
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Title
            Text("The Dungeon")
                .font(.custom("TTPhobosTrial-Bold", size: 28))
                .foregroundColor(colorThemeManager.current.text)
            
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(PracticeAndLeaderboardView.DungeonTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(tab.icon)
                                .font(.system(size: 24))
                            
                            Text(tab.dungeonTitle)
                                .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                                .foregroundColor(
                                    selectedTab == tab ? 
                                    colorThemeManager.current.text : 
                                    colorThemeManager.current.text.opacity(0.6)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    selectedTab == tab ? 
                                    colorThemeManager.current.tabBar : 
                                    Color.clear
                                )
                                .shadow(
                                    color: selectedTab == tab ? colorThemeManager.current.accent.opacity(0.1) : Color.clear,
                                    radius: selectedTab == tab ? 8 : 0,
                                    y: selectedTab == tab ? 2 : 0
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorThemeManager.current.tabBar.opacity(0.3))
                    .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ContentView()
}
