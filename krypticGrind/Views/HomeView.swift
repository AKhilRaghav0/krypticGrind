//
//  HomeView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

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
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                // Sticky title bar when scrolled
                if scrollOffset < -50 {
                    VStack {
                        HStack {
                            Text("KrypticGrind")
                                .font(.custom("TTPhobosTrial-Bold", size: 24))
                                .foregroundColor(colorThemeManager.current.text)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 50)
                        .background(
                            colorThemeManager.current.background.opacity(0.95)
                                .blur(radius: 10)
                        )
                        Spacer()
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: scrollOffset < -50)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer().frame(height: 12)
                        
                        // Main Title
                        Text("KrypticGrind")
                            .font(.custom("TTPhobosTrial-Bold", size: 32))
                            .foregroundColor(colorThemeManager.current.text)
                            .padding(.top, 8)
                        
                        // Streak Section
                        StreakCard()
                            .padding(.horizontal, 20)
                        
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
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(colorThemeManager.current.tabBar.opacity(0.7))
                                .frame(height: 120)
                                .overlay(
                                    Text("No upcoming contests")
                                        .font(.custom("TTPhobosTrial-Bold", size: 20))
                                        .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                                )
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
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task { await cfService.refreshData() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                ThemeSelectorSheet()
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
    
    /// Calculates the user's current daily problem-solving streak based on accepted submissions within the last 30 days.
    /// - Returns: The number of consecutive days, up to 30, with at least one accepted submission per day, counting backward from today.
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

// MARK: - Color Extensions
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
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
    
    /// Asynchronously generates personalized AI suggestions for the user based on recent submission data and user statistics.
    /// Gathers metrics such as acceptance rate, most used language, top problem topics, current streak, and weekly activity, then requests suggestions from the AI service.
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
    
    /// Calculates the user's current daily accepted submission streak, counting consecutive days up to 30 where at least one accepted submission was made.
    /// - Returns: The number of consecutive days, including today, with at least one accepted submission.
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
    /// Updates the preference value with the next reported scroll offset.
    /// - Parameters:
    ///   - value: The current accumulated scroll offset value.
    ///   - nextValue: A closure that returns the next scroll offset value to use.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    HomeView()
}
