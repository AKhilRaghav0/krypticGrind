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
            
            // Tab Selector with Sliding Glass Effect
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorThemeManager.current.tabBar.opacity(0.3))
                    .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1)
                
                // Sliding glass background
                GeometryReader { geometry in
                    let tabWidth = geometry.size.width / CGFloat(PracticeAndLeaderboardView.DungeonTab.allCases.count)
                    let selectedIndex = PracticeAndLeaderboardView.DungeonTab.allCases.firstIndex(of: selectedTab) ?? 0
                    
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colorThemeManager.current.tabBar.opacity(0.8),
                                    colorThemeManager.current.tabBar.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            colorThemeManager.current.accent.opacity(0.4),
                                            colorThemeManager.current.accent.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .overlay(
                            // Glass shine effect
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .white.opacity(0.3), location: 0),
                                            .init(color: .white.opacity(0.1), location: 0.3),
                                            .init(color: .clear, location: 0.7),
                                            .init(color: .white.opacity(0.1), location: 1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .frame(width: tabWidth - 8)
                        .offset(x: CGFloat(selectedIndex) * tabWidth + 4)
                        .shadow(color: colorThemeManager.current.accent.opacity(0.3), radius: 8, x: 0, y: 2)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: selectedTab)
                }
                
                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(PracticeAndLeaderboardView.DungeonTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(tab.icon)
                                    .font(.system(size: selectedTab == tab ? 26 : 24))
                                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                                
                                Text(tab.dungeonTitle)
                                    .font(.custom("TTPhobosTrial-DemiBold", size: selectedTab == tab ? 17 : 16))
                                    .foregroundColor(
                                        selectedTab == tab ? 
                                        colorThemeManager.current.text : 
                                        colorThemeManager.current.text.opacity(0.6)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0), value: selectedTab)
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    ContentView()
}
