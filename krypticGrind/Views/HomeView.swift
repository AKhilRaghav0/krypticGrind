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
    var body: some View {
        ZStack {
            // Minimal, flat background
            Color(.systemBackground)
                .ignoresSafeArea(edges: .top)
            HStack {
                Button(action: onProfile) {
                    Circle()
                        .fill(Color.secondary.opacity(0.13))
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
                    .foregroundColor(.primary)
                Spacer()
                Button(action: onReload) {
                    Circle()
                        .fill(Color.secondary.opacity(0.13))
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
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingSettingsSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                VStack(spacing: 32) {
                    Spacer().frame(height: 12)
                    // Title
                    Text("KrypticGrind")
                        .font(.custom("TTPhobosTrial-Bold", size: 32))
                        .foregroundColor(themeManager.colors.textPrimary)
                        .padding(.top, 8)
                    // Next Contest Card
                    if let nextContest = cfService.nextContest {
                        ContestNextUpCard(contest: nextContest, accent: themeManager.colors.accent)
                            .padding(.horizontal, 20)
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(themeManager.colors.surface.opacity(0.7))
                            .frame(height: 120)
                            .overlay(
                                Text("No upcoming contests")
                                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                                    .foregroundColor(themeManager.colors.textPrimary.opacity(0.5))
                            )
                            .padding(.horizontal, 20)
                    }
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task { await cfService.refreshData() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .tint(themeManager.colors.accent)
    }
}

// MARK: - Modern User Profile Card
struct ModernUserProfileCard: View {
    let user: CFUser
    
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
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("@\(user.handle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
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
                .padding(.horizontal, 16)
            
            // Rating stats
            HStack(spacing: 0) {
                StatColumn(
                    title: "Current",
                    value: "\(user.rating)",
                    color: Color.ratingColor(for: user.rating)
                )
                
                Divider()
                    .frame(height: 40)
                
                StatColumn(
                    title: "Max",
                    value: "\(user.maxRating)",
                    color: Color.ratingColor(for: user.maxRating)
                )
                
                Divider()
                    .frame(height: 40)
                
                StatColumn(
                    title: "Contribution",
                    value: "\(user.contribution)",
                    color: user.contribution >= 0 ? .green : .red
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StatColumn: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
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
                color: .orange,
                subtitle: "participated"
            )
            
            ModernStatCard(
                title: "Submissions",
                value: "\(cfService.recentSubmissions.count)",
                icon: "doc.text.fill",
                color: .blue,
                subtitle: "total"
            )
            
            ModernStatCard(
                title: "Accepted",
                value: "\(cfService.recentSubmissions.acceptedSubmissions().count)",
                icon: "checkmark.circle.fill",
                color: .green,
                subtitle: "solved"
            )
        }
    }
}



// MARK: - Modern Progress Card
struct ModernProgressCard: View {
    @StateObject private var cfService = CFService.shared
    
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
                        .foregroundStyle(.primary)
                    
                    Text("\(todaysAccepted.count) of \(dailyGoal) problems solved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if progress >= 1.0 {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: progress)
                }
            }
            
            // Modern progress bar
            ProgressView(value: progress) {
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .progressViewStyle(.linear)
            .tint(.blue)
            .scaleEffect(y: 1.5)
            
            HStack {
                Label("\(todaysSubmissions.count) submissions today", systemImage: "paperplane.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if progress >= 1.0 {
                    Text("Goal achieved! 🎉")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                } else {
                    Text("\(dailyGoal - todaysAccepted.count) more to go")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Modern Activity Card
struct ModernActivityCard: View {
    @StateObject private var cfService = CFService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                NavigationLink(destination: SubmissionsView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(cfService.recentSubmissions.prefix(4)) { submission in
                    ModernSubmissionRow(submission: submission)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ModernSubmissionRow: View {
    let submission: CFSubmission
    
    var body: some View {
        HStack(spacing: 12) {
            // Verdict indicator
            Circle()
                .fill(Color.verdictColor(for: submission.verdict ?? ""))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(submission.problem.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("\(submission.problem.index) • \(submission.programmingLanguage)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(submission.verdictDisplayText)
                    .font(.caption.bold())
                    .foregroundStyle(Color.verdictColor(for: submission.verdict ?? ""))
                
                Text(submission.submissionDate.timeAgo())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Welcome Card
struct WelcomeCard: View {
    @State private var showingHandleInput = false
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.colors.accent)
                .shadow(color: themeManager.colors.accent.opacity(0.6), radius: 10)
            
            Text("Welcome to KrypticGrind")
                .font(.largeTitle.bold())
                .foregroundColor(themeManager.colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Track your Codeforces journey with style. Enter your handle to get started.")
                .font(.body)
                .foregroundColor(themeManager.colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingHandleInput = true
            }) {
                Text("Get Started")
                    .font(.headline.bold())
                    .foregroundColor(themeManager.colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.colors.accent)
                    .cornerRadius(12)
                    .shadow(color: themeManager.colors.accent.opacity(0.6), radius: 10)
            }
        }
        .padding(30)
        .background(themeManager.colors.surface)
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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(themeManager.colors.warning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Connection Issue")
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.colors.textPrimary)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(themeManager.colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onRetry) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.colors.textPrimary))
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(themeManager.colors.accent)
                }
            }
            .disabled(isLoading)
        }
        .padding()
        .background(themeManager.colors.surface)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Modern Loading View
struct ModernLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading your data...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Error Banner View
struct ErrorBannerView: View {
    let message: String
    let isLoading: Bool
    let onRetry: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Modern Welcome Card
struct ModernWelcomeCard: View {
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 8) {
                Text("Welcome to KrypticGrind")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text("Track your competitive programming journey")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text("Get Started")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.gradient)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// Minimal Contest Next Up Card
struct ContestNextUpCard: View {
    let contest: CFContest
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Up")
                .font(.custom("TTPhobosTrial-Bold", size: 18))
                .foregroundColor(accent)
            Text(contest.name)
                .font(.custom("TTPhobosTrial-Bold", size: 22))
                .foregroundColor(.primary)
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(accent)
                Text(contest.startDate?.formatted(date: .abbreviated, time: .shortened) ?? "TBD")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                if let url = URL(string: contest.contestUrl) {
                    Link(destination: url) {
                        Text("Details")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
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
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

#Preview {
    HomeView()
}
