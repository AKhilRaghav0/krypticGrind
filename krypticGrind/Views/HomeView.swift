//
//  HomeView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI
import Foundation

// Note: In a real iOS project, these would be properly imported from their respective files
// For now, we'll assume all the custom types are available in the same module

// MARK: - Custom Minimal Top Bar
struct CustomTopBar: View {
    let title: String
    let onProfile: () -> Void
    let onReload: () -> Void
    let accent: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            // Minimal, flat background
            colorThemeManager.current.tabBar
                .ignoresSafeArea(edges: .top)
            HStack {
                Button(action: onProfile) {
                    Circle()
                        .fill(colorThemeManager.current.text.opacity(0.13))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(accent)
                        )
                }
                Spacer()
                Text(title)
                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                    .foregroundColor(colorThemeManager.current.text)
                Spacer()
                Button(action: onReload) {
                    Circle()
                        .fill(colorThemeManager.current.text.opacity(0.13))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(accent)
                        )
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
        }
        .frame(height: 48 + 20) // Fixed safe area inset
        .padding(.top, 20) // Fixed safe area inset
    }
}

struct HomeView: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var showingSettingsSheet = false
    @State private var isRefreshing = false
    @State private var showSwordAnimation = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                // Sword fighting animation overlay
                if showSwordAnimation {
                    SwordFightingOverlay()
                        .transition(.opacity)
                        .zIndex(1)
                }
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Top spacing
                        Spacer().frame(height: 20)
                        
                        // Main Title with User Avatar
                        HStack(spacing: 16) {
                            // User Avatar from Codeforces
                            if let user = cfService.currentUser {
                                AsyncImage(url: URL(string: user.avatar)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(colorThemeManager.current.accent.opacity(0.2))
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(colorThemeManager.current.accent)
                                                .font(.system(size: 20))
                                        }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(colorThemeManager.current.accent, lineWidth: 2)
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("KrypticGrind")
                                    .font(.custom("TTPhobosTrial-Bold", size: 28))
                                    .foregroundColor(colorThemeManager.current.text)
                                
                                if let user = cfService.currentUser {
                                    HStack(spacing: 8) {
                                        Text("@\(user.handle)")
                                            .font(.custom("TTPhobosTrial-Regular", size: 14))
                                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                                        
                                        // Rating badge
                                        Text("\(user.rating)")
                                            .font(.custom("TTPhobosTrial-Bold", size: 12))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color.ratingColor(for: user.rating))
                                            )
                                    }
                                } else {
                                    Text("Ready for battle!")
                                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            // Settings button
                            Button(action: { showingSettingsSheet = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(colorThemeManager.current.accent)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(colorThemeManager.current.tabBar.opacity(0.6))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Enhanced Daily Streak Card
                        EnhancedStreakCard()
                            .padding(.horizontal, 20)
                        
                        // GitHub-like Streak Grid
                        GitHubStyleStreakGrid()
                            .padding(.horizontal, 20)
                        
                        // User Stats Overview (if user exists)
                        if let user = cfService.currentUser {
                            UserStatsOverview(user: user)
                                .padding(.horizontal, 20)
                        }
                        
                        // AI Suggestions Card
                        if let user = cfService.currentUser {
                            AISuggestionsCard(user: user)
                                .padding(.horizontal, 20)
                        }
                        
                        // Next Contest Card
                        if let nextContest = cfService.nextContest {
                            ContestNextUpCard(contest: nextContest, accent: colorThemeManager.current.accent)
                                .padding(.horizontal, 20)
                        } else {
                            EmptyContestCard()
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer().frame(height: 50)
                    }
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .refreshable {
                    await performSwordRefresh()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettingsSheet) {
                EnhancedSettingsSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .tint(colorThemeManager.current.accent)
        .onAppear {
            // Load saved handle if available
            if let savedHandle = UserDefaults.standard.savedHandle,
               cfService.currentUser == nil {
                Task {
                    await cfService.fetchAllUserData(handle: savedHandle)
                }
            }
        }
    }
    
    private func performSwordRefresh() async {
        // Show sword animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showSwordAnimation = true
        }
        
        // Wait for animation and refresh data
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        await cfService.refreshData()
        
        // Hide animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showSwordAnimation = false
        }
    }
}

// MARK: - Modern User Profile Card
struct ModernUserProfileCard: View {
    let user: CFUser
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with avatar and basic info
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: user.avatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(colorThemeManager.current.text.opacity(0.6).opacity(0.2))
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                        }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(colorThemeManager.current.text)
                    
                    Text("@\(user.handle)")
                        .font(.subheadline)
                        .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                    
                    HStack(spacing: 8) {
                        Text(user.rank)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.ratingColor(for: user.rating), in: Capsule())
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(colorThemeManager.current.text.opacity(0.2))
                .padding(.horizontal, 16)
            
            // Rating stats
            HStack(spacing: 0) {
                StatColumn(
                    title: "Current",
                    value: "\(user.rating)",
                    color: Color.ratingColor(for: user.rating)
                )
                
                Divider()
                    .background(colorThemeManager.current.text.opacity(0.2))
                    .frame(height: 40)
                
                StatColumn(
                    title: "Max",
                    value: "\(user.maxRating)",
                    color: Color.ratingColor(for: user.maxRating)
                )
                
                Divider()
                    .background(colorThemeManager.current.text.opacity(0.2))
                    .frame(height: 40)
                
                StatColumn(
                    title: "Contribution",
                    value: "\(user.contribution)",
                    color: user.contribution >= 0 ? Color.green : Color.red
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatColumn: View {
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
            
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Stats Grid
struct ModernStatsGrid: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ModernStatCard(
                title: "Contests",
                value: "\(cfService.ratingHistory.count)",
                icon: "trophy.fill",
                color: Color.orange,
                subtitle: "participated"
            )
            
            ModernStatCard(
                title: "Submissions",
                value: "\(cfService.recentSubmissions.count)",
                icon: "doc.text.fill",
                color: colorThemeManager.current.accent,
                subtitle: "total"
            )
            
            ModernStatCard(
                title: "Accepted",
                value: "\(cfService.recentSubmissions.acceptedSubmissions().count)",
                icon: "checkmark.circle.fill",
                color: Color.green,
                subtitle: "solved"
            )
        }
    }
}

// MARK: - Modern Progress Card
struct ModernProgressCard: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        let todaysSubmissions = cfService.recentSubmissions.todaysSubmissions()
        let todaysAccepted = todaysSubmissions.acceptedSubmissions()
        let dailyGoal = UserDefaults.standard.dailyGoal
        let progress = Double(todaysAccepted.count) / Double(dailyGoal)
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.headline)
                        .foregroundStyle(colorThemeManager.current.text)
                    
                    Text("\(todaysAccepted.count) of \(dailyGoal) problems solved")
                        .font(.subheadline)
                        .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                }
                
                Spacer()
                
                if progress >= 1.0 {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(Color.orange)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: progress)
                }
            }
            
            // Modern progress bar
            ProgressView(value: progress) {
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                    Spacer()
                }
            }
            .progressViewStyle(.linear)
            .tint(colorThemeManager.current.accent)
            .scaleEffect(y: 1.5)
            
            HStack {
                Label("\(todaysSubmissions.count) submissions today", systemImage: "paperplane.fill")
                    .font(.caption)
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                
                Spacer()
                
                if progress >= 1.0 {
                    Text("Goal achieved! 🎉")
                        .font(.caption.bold())
                        .foregroundStyle(Color.green)
                } else {
                    Text("\(dailyGoal - todaysAccepted.count) more to go")
                        .font(.caption)
                        .foregroundStyle(Color.orange)
                }
            }
        }
        .padding(16)
        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Modern Activity Card
struct ModernActivityCard: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundStyle(colorThemeManager.current.text)
                
                Spacer()
                
                NavigationLink(destination: SubmissionsView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(colorThemeManager.current.accent)
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(cfService.recentSubmissions.prefix(4)) { submission in
                    ModernSubmissionRow(submission: submission)
                }
            }
        }
        .padding(16)
        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ModernSubmissionRow: View {
    let submission: CFSubmission
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Verdict indicator
            Circle()
                .fill(Color.verdictColor(for: submission.verdict ?? ""))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(submission.problem.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(colorThemeManager.current.text)
                    .lineLimit(1)
                
                Text("\(submission.problem.index) • \(submission.programmingLanguage)")
                    .font(.caption)
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(submission.verdictDisplayText)
                    .font(.caption.bold())
                    .foregroundStyle(Color.verdictColor(for: submission.verdict ?? ""))
                
                Text(submission.submissionDate.timeAgo())
                    .font(.caption)
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Welcome Card
struct WelcomeCard: View {
    @State private var showingHandleInput = false
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(colorThemeManager.current.accent)
                .shadow(color: colorThemeManager.current.accent.opacity(0.6), radius: 10)
            
            Text("Welcome to KrypticGrind")
                .font(.largeTitle.bold())
                .foregroundColor(colorThemeManager.current.text)
                .multilineTextAlignment(.center)
            
            Text("Track your Codeforces journey with style. Enter your handle to get started.")
                .font(.body)
                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingHandleInput = true
            }) {
                Text("Get Started")
                    .font(.headline.bold())
                    .foregroundColor(colorThemeManager.current.text)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorThemeManager.current.accent)
                    .cornerRadius(12)
                    .shadow(color: colorThemeManager.current.accent.opacity(0.6), radius: 10)
            }
        }
        .padding(30)
        .background(colorThemeManager.current.tabBar)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingHandleInput) {
            HandleInputSheet(handleInput: .constant("")) {
                // Handle submission
                showingHandleInput = false
            }
        }
    }
}

// MARK: - Error Retry View for Home
struct ErrorRetryHomeView: View {
    let message: String
    let isLoading: Bool
    let onRetry: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(Color.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Connection Issue")
                    .font(.subheadline.bold())
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onRetry) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: colorThemeManager.current.text))
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(colorThemeManager.current.accent)
                }
            }
            .disabled(isLoading)
        }
        .padding()
        .background(colorThemeManager.current.tabBar)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Modern Loading View
struct ModernLoadingView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading your data...")
                .font(.subheadline)
                .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Error Banner View
struct ErrorBannerView: View {
    let message: String
    let isLoading: Bool
    let onRetry: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.subheadline.bold())
                    .foregroundStyle(colorThemeManager.current.text)
                
                Text(message)
                    .font(.caption)
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isLoading)
        }
        .padding()
        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Modern Welcome Card
struct ModernWelcomeCard: View {
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(colorThemeManager.current.accent.gradient)
            
            VStack(spacing: 8) {
                Text("Welcome to KrypticGrind")
                    .font(.title2.bold())
                    .foregroundStyle(colorThemeManager.current.text)
                
                Text("Track your competitive programming journey")
                    .font(.subheadline)
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text("Get Started")
                    .font(.headline.bold())
                    .foregroundStyle(colorThemeManager.current.text)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorThemeManager.current.accent.gradient)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(colorThemeManager.current.tabBar, in: RoundedRectangle(cornerRadius: 16))
    }
}

// Minimal Contest Next Up Card
struct ContestNextUpCard: View {
    let contest: CFContest
    let accent: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Up")
                .font(.custom("TTPhobosTrial-Bold", size: 18))
                .foregroundColor(accent)
            Text(contest.name)
                .font(.custom("TTPhobosTrial-Bold", size: 22))
                .foregroundColor(colorThemeManager.current.text)
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(accent)
                Text(contest.startDate?.formatted(date: .abbreviated, time: .shortened) ?? "TBD")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                Spacer()
                if let url = URL(string: contest.contestUrl) {
                    Link(destination: url) {
                        Text("Details")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colorThemeManager.current.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(accent)
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    private var todaysSolved: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return cfService.recentSubmissions.filter { submission in
            let submissionDate = calendar.startOfDay(for: submission.submissionDate)
            return submissionDate >= today && submissionDate < tomorrow && 
                   (submission.verdict == "OK" || submission.verdict == "ACCEPTED")
        }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Streak")
                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                        .foregroundColor(colorThemeManager.current.accent)
                    
                    Text("\(currentStreak) day\(currentStreak == 1 ? "" : "s")")
                        .font(.custom("TTPhobosTrial-Bold", size: 24))
                        .foregroundColor(colorThemeManager.current.text)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Today")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    
                    Text("\(todaysSolved) solved")
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(todaysSolved > 0 ? Color.green : colorThemeManager.current.text.opacity(0.6))
                }
            }
            
            // Fire Icons Row
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    FireIcon(
                        isActive: index < min(currentStreak, 5),
                        index: index,
                        totalStreak: currentStreak
                    )
                }
            }
            .padding(.vertical, 8)
            
            // Motivational Text
            HStack {
                Image(systemName: motivationalIcon)
                    .foregroundColor(motivationalColor)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(motivationalText)
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
    
    private var motivationalText: String {
        switch currentStreak {
        case 0:
            return todaysSolved > 0 ? "Great start! Keep going!" : "Start your streak by solving a problem today!"
        case 1...2:
            return "You're building momentum! 🚀"
        case 3...6:
            return "Fantastic streak! You're on fire! 🔥"
        case 7...13:
            return "Incredible consistency! A week strong! ⭐"
        case 14...29:
            return "Legendary dedication! Two weeks+! 👑"
        default:
            return "Unstoppable coding machine! 🏆"
        }
    }
    
    private var motivationalIcon: String {
        switch currentStreak {
        case 0:
            return todaysSolved > 0 ? "bolt.circle.fill" : "target"
        case 1...2:
            return "arrow.up.circle.fill"
        case 3...6:
            return "flame.fill"
        case 7...13:
            return "star.fill"
        case 14...29:
            return "crown.fill"
        default:
            return "trophy.fill"
        }
    }
    
    private var motivationalColor: Color {
        switch currentStreak {
        case 0:
            return todaysSolved > 0 ? Color.green : colorThemeManager.current.accent
        case 1...2:
            return Color.blue
        case 3...6:
            return Color.orange
        case 7...13:
            return Color.yellow
        case 14...29:
            return Color.purple
        default:
            return Color.gold
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Check if today has submissions first
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let hasTodaySubmission = cfService.recentSubmissions.contains { submission in
            let submissionDate = calendar.startOfDay(for: submission.submissionDate)
            return submissionDate >= today && submissionDate < tomorrow && 
                   (submission.verdict == "OK" || submission.verdict == "ACCEPTED")
        }
        
        if hasTodaySubmission {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        // Check previous days
        for _ in 0..<29 {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let hasSubmission = cfService.recentSubmissions.contains { submission in
                let submissionDate = calendar.startOfDay(for: submission.submissionDate)
                return submissionDate >= currentDate && submissionDate < nextDate && 
                       (submission.verdict == "OK" || submission.verdict == "ACCEPTED")
            }
            
            if hasSubmission {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Fire Icon Component
struct FireIcon: View {
    let isActive: Bool
    let index: Int
    let totalStreak: Int
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Text("🔥")
            .font(.system(size: 24))
            .opacity(isActive ? 1.0 : 0.3)
            .scaleEffect(isActive ? 1.0 : 0.8)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
    
    private var fireColor: Color {
        switch index {
        case 0:
            return Color.orange
        case 1:
            return Color.red
        case 2:
            return Color.pink
        case 3:
            return Color.purple
        case 4:
            return Color.blue
        default:
            return Color.orange
        }
    }
}

// MARK: - AI Suggestions Card
struct AISuggestionsCard: View {
    let user: CFUser
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("🧠")
                            .font(.title2)
                        Text("AI Coach")
                            .font(.custom("TTPhobosTrial-Bold", size: 18))
                            .foregroundColor(colorThemeManager.current.text)
                    }
                    
                    Text("Personalized recommendations")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
                
                Spacer()
                
                if !geminiService.isLoading {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
            }
            
            // Content
            if geminiService.isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(colorThemeManager.current.accent)
                    Text("AI is analyzing your performance...")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else if let error = geminiService.error {
                VStack(spacing: 8) {
                    Text("⚠️ Unable to get suggestions")
                        .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            } else if geminiService.suggestions.isEmpty {
                VStack(spacing: 12) {
                    Text("✨ Get started with AI coaching")
                        .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Button(action: {
                        Task {
                            await generateSuggestions()
                        }
                    }) {
                        Text("Generate Suggestions")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(colorThemeManager.current.accent)
                            )
                    }
                }
            } else {
                VStack(spacing: 12) {
                    // Show first suggestion always
                    if let firstSuggestion = geminiService.suggestions.first {
                        SuggestionRow(suggestion: firstSuggestion, isCompact: !isExpanded)
                    }
                    
                    // Show additional suggestions if expanded
                    if isExpanded {
                        ForEach(Array(geminiService.suggestions.dropFirst().prefix(2)), id: \.id) { suggestion in
                            SuggestionRow(suggestion: suggestion, isCompact: false)
                        }
                        
                        NavigationLink(destination: AISuggestionsView()) {
                            HStack {
                                Text("View all suggestions")
                                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                                    .foregroundColor(colorThemeManager.current.accent)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(colorThemeManager.current.accent)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
        .onAppear {
            if geminiService.suggestions.isEmpty {
                Task {
                    await generateSuggestions()
                }
            }
        }
        .onChange(of: cfService.recentSubmissions) { _, _ in
            // Refresh suggestions when new submission data is available
            Task {
                await generateSuggestions()
            }
        }
    }
    
    private func generateSuggestions() async {
        let acceptedSubmissions = cfService.recentSubmissions.filter { $0.isAccepted }
        let totalSubmissions = cfService.recentSubmissions.count
        let acceptanceRate = totalSubmissions > 0 ? Double(acceptedSubmissions.count) / Double(totalSubmissions) * 100 : 0
        let mostUsedLanguage = Dictionary(grouping: cfService.recentSubmissions, by: { $0.programmingLanguage })
            .max(by: { $0.value.count < $1.value.count })?.key ?? "Unknown"
        let topTopics = Array(Dictionary(grouping: acceptedSubmissions) { $0.problem.tags.first ?? "unknown" }
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map { $0.key })
        
        let userStats = UserStats(
            totalSubmissions: totalSubmissions,
            acceptedSubmissions: acceptedSubmissions.count,
            acceptanceRate: acceptanceRate,
            mostUsedLanguage: mostUsedLanguage,
            currentStreak: calculateCurrentStreak(),
            weeklySubmissions: cfService.recentSubmissions.filter { $0.submissionDate > Date().addingTimeInterval(-7*24*60*60) }.count,
            topTopics: topTopics,
            recentPerformance: "Recent performance analysis"
        )
        
        await geminiService.generateSuggestions(
            userStats: userStats,
            submissions: cfService.recentSubmissions,
            user: user
        )
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let acceptedSubmissions = cfService.recentSubmissions
            .filter { $0.isAccepted }
            .sorted { $0.submissionDate > $1.submissionDate }
        
        var streak = 0
        var currentDate = today
        
        for _ in 0..<30 { // Check last 30 days
            let hasSubmissionThisDay = acceptedSubmissions.contains { submission in
                calendar.isDate(submission.submissionDate, inSameDayAs: currentDate)
            }
            
            if hasSubmissionThisDay {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Suggestion Row
struct SuggestionRow: View {
    let suggestion: AISuggestion
    let isCompact: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    .foregroundColor(colorThemeManager.current.text)
                    .lineLimit(1)
                
                if !isCompact {
                    Text(suggestion.description)
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if let url = suggestion.actionURL, let nsUrl = URL(string: url) {
                Link(destination: nsUrl) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(colorThemeManager.current.accent)
                }
            }
        }
        .padding(.vertical, isCompact ? 4 : 8)
    }
    
    private var priorityColor: Color {
        switch suggestion.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Sword Fighting Animation Overlay
struct SwordFightingOverlay: View {
    @State private var swordRotation1: Double = 0
    @State private var swordRotation2: Double = 0
    @State private var sparkleOpacity: Double = 0
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            colorThemeManager.current.background.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Sword fighting animation
                ZStack {
                    // Sparkles
                    ForEach(0..<8, id: \.self) { index in
                        Text("✨")
                            .font(.system(size: 20))
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 40,
                                y: sin(Double(index) * .pi / 4) * 40
                            )
                            .opacity(sparkleOpacity)
                    }
                    
                    // Crossing swords
                    HStack(spacing: -10) {
                        Text("⚔️")
                            .font(.system(size: 60))
                            .rotationEffect(.degrees(swordRotation1))
                        
                        Text("⚔️")
                            .font(.system(size: 60))
                            .rotationEffect(.degrees(swordRotation2))
                            .scaleEffect(x: -1)
                    }
                }
                
                Text("Refreshing Battle Data...")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                swordRotation1 = 15
                swordRotation2 = -15
            }
            
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                sparkleOpacity = 1.0
            }
        }
    }
}

// MARK: - Enhanced Streak Card
struct EnhancedStreakCard: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    private var todaysSolved: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return cfService.recentSubmissions.filter { submission in
            let submissionDate = calendar.startOfDay(for: submission.submissionDate)
            return submissionDate >= today && submissionDate < tomorrow && 
                   (submission.verdict == "OK" || submission.verdict == "ACCEPTED")
        }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Main streak display
            HStack(spacing: 20) {
                // Streak flame
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: currentStreak > 0 ? [.orange, .red] : [colorThemeManager.current.text.opacity(0.2), colorThemeManager.current.text.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Text(currentStreak > 0 ? "🔥" : "⭕")
                            .font(.system(size: 40))
                    }
                    
                    Text("Streak")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Current streak
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(currentStreak)")
                            .font(.custom("TTPhobosTrial-Bold", size: 36))
                            .foregroundColor(colorThemeManager.current.text)
                        
                        Text("day\(currentStreak == 1 ? "" : "s") streak")
                            .font(.custom("TTPhobosTrial-Regular", size: 14))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                    
                    // Today's progress
                    HStack(spacing: 8) {
                        Text("Today:")
                            .font(.custom("TTPhobosTrial-Regular", size: 14))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                        
                        Text("\(todaysSolved) solved")
                            .font(.custom("TTPhobosTrial-Bold", size: 14))
                            .foregroundColor(todaysSolved > 0 ? .green : colorThemeManager.current.text.opacity(0.6))
                        
                        if todaysSolved > 0 {
                            Text("✅")
                                .font(.system(size: 12))
                        }
                    }
                }
                
                Spacer()
            }
            
            // Fire Icons Row
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    FireIcon(
                        isActive: index < min(currentStreak, 5),
                        index: index,
                        totalStreak: currentStreak
                    )
                }
            }
            .padding(.vertical, 8)
            
            // Motivational Text
            HStack {
                Image(systemName: motivationalIcon)
                    .foregroundColor(motivationalColor)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(motivationalText)
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
    
    private var motivationalText: String {
        switch currentStreak {
        case 0:
            return todaysSolved > 0 ? "Great start! Keep going!" : "Start your streak by solving a problem today!"
        case 1...2:
            return "You're building momentum! 🚀"
        case 3...6:
            return "Fantastic streak! You're on fire! 🔥"
        case 7...13:
            return "Incredible consistency! A week strong! ⭐"
        case 14...29:
            return "Legendary dedication! Two weeks+! 👑"
        default:
            return "Unstoppable coding machine! 🏆"
        }
    }
    
    private var motivationalIcon: String {
        switch currentStreak {
        case 0:
            return todaysSolved > 0 ? "bolt.circle.fill" : "target"
        case 1...2:
            return "arrow.up.circle.fill"
        case 3...6:
            return "flame.fill"
        case 7...13:
            return "star.fill"
        case 14...29:
            return "crown.fill"
        default:
            return "trophy.fill"
        }
    }
    
    private var motivationalColor: Color {
        switch currentStreak {
        case 0:
            return todaysSolved > 0 ? Color.green : colorThemeManager.current.accent
        case 1...2:
            return Color.blue
        case 3...6:
            return Color.orange
        case 7...13:
            return Color.yellow
        case 14...29:
            return Color.purple
        default:
            return Color.gold
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Check if today has submissions first
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let hasTodaySubmission = cfService.recentSubmissions.contains { submission in
            let submissionDate = calendar.startOfDay(for: submission.submissionDate)
            return submissionDate >= today && submissionDate < tomorrow && 
                   (submission.verdict == "OK" || submission.verdict == "ACCEPTED")
        }
        
        if hasTodaySubmission {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        // Check previous days
        for _ in 0..<29 {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let hasSubmission = cfService.recentSubmissions.contains { submission in
                let submissionDate = calendar.startOfDay(for: submission.submissionDate)
                return submissionDate >= currentDate && submissionDate < nextDate && 
                       (submission.verdict == "OK" || submission.verdict == "ACCEPTED")
            }
            
            if hasSubmission {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - GitHub-style Streak Grid
struct GitHubStyleStreakGrid: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity Graph")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("Less")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { intensity in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(getActivityColor(intensity: intensity))
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    Text("More")
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
            }
            
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(getLast91Days(), id: \.self) { date in
                    let activityCount = getActivityCount(for: date)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(getActivityColor(intensity: min(activityCount, 4)))
                        .frame(width: 12, height: 12)
                        .help("Solved \(activityCount) problems on \(date.formatted(date: .abbreviated, time: .omitted))")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.7))
        )
    }
    
    private func getLast91Days() -> [Date] {
        let today = Date()
        return (0..<91).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }.reversed()
    }
    
    private func getActivityCount(for date: Date) -> Int {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        return cfService.recentSubmissions.filter { submission in
            submission.submissionDate >= startOfDay && 
            submission.submissionDate < endOfDay && 
            (submission.verdict == "OK" || submission.verdict == "ACCEPTED")
        }.count
    }
    
    private func getActivityColor(intensity: Int) -> Color {
        switch intensity {
        case 0:
            return colorThemeManager.current.text.opacity(0.05)
        case 1:
            return Color.green.opacity(0.3)
        case 2:
            return Color.green.opacity(0.5)
        case 3:
            return Color.green.opacity(0.7)
        default:
            return Color.green
        }
    }
}

// MARK: - User Stats Overview
struct UserStatsOverview: View {
    let user: CFUser
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Warrior Stats")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatBox(
                    icon: "⚔️",
                    title: "Rating",
                    value: "\(user.rating)",
                    subtitle: user.rank,
                    color: Color.ratingColor(for: user.rating)
                )
                
                StatBox(
                    icon: "🏆",
                    title: "Max Rating",
                    value: "\(user.maxRating)",
                    subtitle: "Peak",
                    color: Color.ratingColor(for: user.maxRating)
                )
                
                StatBox(
                    icon: "⏱️",
                    title: "Contests",
                    value: "\(user.contribution > 0 ? user.contribution : 0)",
                    subtitle: "Battles",
                    color: colorThemeManager.current.accent
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.7))
        )
    }
}

// MARK: - Stat Box Component
struct StatBox: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 10))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Empty Contest Card
struct EmptyContestCard: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("⚔️")
                .font(.system(size: 40))
            
            VStack(spacing: 8) {
                Text("No Battles Ahead")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text("The arena is quiet. Keep training!")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.7))
        )
    }
}

// MARK: - Enhanced Settings Sheet
struct EnhancedSettingsSheet: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @StateObject private var cfService = CFService.shared
    @State private var showingHandleInput = false
    @State private var tempHandle = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)
                        
                        // User Profile Section
                        if let user = cfService.currentUser {
                            UserProfileSection(user: user)
                        } else {
                            NoUserSection(showingHandleInput: $showingHandleInput)
                        }
                        
                        // Theme Selection Section
                        ThemeSelectionSection()
                        
                        // Settings Actions
                        SettingsActionsSection(showingHandleInput: $showingHandleInput)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorThemeManager.current.accent)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                }
            }
        }
        .sheet(isPresented: $showingHandleInput) {
            HandleInputSheet(handleInput: $tempHandle) {
                // Handle submission
                Task {
                    await cfService.fetchAllUserData(handle: tempHandle)
                }
                showingHandleInput = false
            }
        }
    }
}

// MARK: - Settings Sheet Components
struct UserProfileSection: View {
    let user: CFUser
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Warrior Profile")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: user.avatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(colorThemeManager.current.accent.opacity(0.2))
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(colorThemeManager.current.accent)
                        }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.ratingColor(for: user.rating), lineWidth: 3)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Text("@\(user.handle)")
                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    
                    HStack(spacing: 8) {
                        Text(user.rank)
                            .font(.custom("TTPhobosTrial-Bold", size: 12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.ratingColor(for: user.rating))
                            )
                        
                        Text("\(user.rating)")
                            .font(.custom("TTPhobosTrial-Bold", size: 12))
                            .foregroundColor(Color.ratingColor(for: user.rating))
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.7))
        )
    }
}

struct NoUserSection: View {
    @Binding var showingHandleInput: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("⚔️")
                .font(.system(size: 40))
            
            VStack(spacing: 8) {
                Text("Ready for Battle?")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text("Connect your Codeforces account to start tracking your progress")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingHandleInput = true }) {
                Text("Enter Username")
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorThemeManager.current.accent)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.7))
        )
    }
}

struct ThemeSelectionSection: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Battle Theme")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(ColorTheme.allCases, id: \.self) { theme in
                    ThemeOptionCard(theme: theme, isSelected: colorThemeManager.selectedTheme == theme)
                        .onTapGesture {
                            colorThemeManager.selectedTheme = theme
                        }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.7))
        )
    }
}

struct ThemeOptionCard: View {
    let theme: ColorTheme
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.colors.background)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.colors.accent, lineWidth: 2)
                )
                .overlay(
                    Circle()
                        .fill(theme.colors.accent)
                        .frame(width: 16, height: 16)
                )
            
            Text(theme.name)
                .font(.custom("TTPhobosTrial-Regular", size: 12))
                .foregroundColor(theme.colors.text)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.tabBar.opacity(0.5))
                .stroke(isSelected ? theme.colors.accent : Color.clear, lineWidth: 2)
        )
    }
}

struct SettingsActionsSection: View {
    @Binding var showingHandleInput: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @StateObject private var cfService = CFService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Actions")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingsActionRow(
                    icon: "person.badge.plus",
                    title: cfService.currentUser != nil ? "Change Username" : "Add Username",
                    subtitle: "Connect or switch Codeforces account",
                    color: .blue
                ) {
                    showingHandleInput = true
                }
                
                if cfService.currentUser != nil {
                    SettingsActionRow(
                        icon: "arrow.clockwise",
                        title: "Refresh Data",
                        subtitle: "Update your latest stats",
                        color: .green
                    ) {
                        Task {
                            await cfService.refreshData()
                        }
                    }
                    
                    SettingsActionRow(
                        icon: "trash",
                        title: "Clear Data",
                        subtitle: "Remove all saved information",
                        color: .red
                    ) {
                        cfService.clearAllData()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.7))
        )
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("TTPhobosTrial-Bold", size: 15))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Text(subtitle)
                        .font(.custom("TTPhobosTrial-Regular", size: 13))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(colorThemeManager.current.text.opacity(0.4))
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorThemeManager.current.tabBar.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
