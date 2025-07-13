//
//  OnboardingView.swift
//  KrypticGrind
//
//  Created by akhil on 14/07/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var colorThemeManager = ColorThemeManager()
    @State private var currentPage = 0
    @State private var showGetStarted = false
    @Binding var isFirstLaunch: Bool
    
    let pages = [
        OnboardingPage(
            title: "Welcome to KrypticGrind",
            subtitle: "Your Ultimate Competitive Programming Companion",
            description: "Master algorithmic thinking and climb the ratings ladder with AI-powered insights and comprehensive tracking.",
            systemImage: "star.fill",
            accentColor: Color.blue
        ),
        OnboardingPage(
            title: "Track Your Progress",
            subtitle: "Real-time Performance Analytics",
            description: "Monitor your Codeforces submissions, analyze your strengths and weaknesses, and track your rating growth over time.",
            systemImage: "chart.line.uptrend.xyaxis",
            accentColor: Color.green
        ),
        OnboardingPage(
            title: "AI-Powered Learning",
            subtitle: "Personalized Practice Suggestions",
            description: "Get intelligent recommendations on topics to focus on, problems to solve, and strategies to improve based on your coding patterns.",
            systemImage: "brain.head.profile",
            accentColor: Color.purple
        ),
        OnboardingPage(
            title: "Contest & Community",
            subtitle: "Stay Competition Ready",
            description: "Never miss upcoming contests, compare with friends on leaderboards, and maintain your solving streak with daily goals.",
            systemImage: "trophy.fill",
            accentColor: Color.orange
        ),
        OnboardingPage(
            title: "Smart Problem Management",
            subtitle: "Organize Your Learning",
            description: "Save problems for later review, take notes on solutions, and build your personal library of solved problems with insights.",
            systemImage: "bookmark.fill",
            accentColor: Color.indigo
        )
    ]
    
    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: [
                    colorThemeManager.current.accent.opacity(0.1),
                    colorThemeManager.current.background,
                    colorThemeManager.current.accent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, colorThemeManager: colorThemeManager)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                // Bottom Controls
                VStack(spacing: 24) {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? colorThemeManager.current.accent : colorThemeManager.current.text.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Navigation Buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Previous") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            }
                            .foregroundStyle(colorThemeManager.current.text.opacity(0.7))
                            .font(.system(size: 16, weight: .medium))
                        }
                        
                        Spacer()
                        
                        if currentPage < pages.count - 1 {
                            Button("Next") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                            .foregroundStyle(colorThemeManager.current.accent)
                            .font(.system(size: 16, weight: .semibold))
                        } else {
                            Button("Get Started") {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showGetStarted = true
                                }
                                
                                // Delay to show animation, then dismiss
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    UserDefaults.standard.set(false, forKey: "isFirstLaunch")
                                    isFirstLaunch = false
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(colorThemeManager.current.accent)
                                    .shadow(color: colorThemeManager.current.accent.opacity(0.3), radius: 10, y: 5)
                            )
                            .foregroundStyle(.white)
                            .font(.system(size: 18, weight: .bold))
                            .scaleEffect(showGetStarted ? 1.1 : 1.0)
                            .opacity(showGetStarted ? 0.8 : 1.0)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Auto-advance pages with a slower interval for reading
            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { timer in
                if currentPage < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPage += 1
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(page.accentColor.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: page.systemImage)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(page.accentColor)
            }
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(colorThemeManager.current.text)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(page.accentColor)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(colorThemeManager.current.text.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let accentColor: Color
}

// MARK: - Preview
#Preview {
    OnboardingView(isFirstLaunch: .constant(true))
}
