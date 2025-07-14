//
//  OnboardingView.swift
//  KrypticGrind
//
//  Created by akhil on 14/07/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct OnboardingView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var currentPage = 0
    @State private var showGetStarted = false
    @State private var animateContent = false
    @State private var dragOffset: CGFloat = 0
    @Binding var isFirstLaunch: Bool
    
    let pages = [
        OnboardingPage(
            title: "Welcome to KrypticGrind",
            subtitle: "Your Ultimate Competitive Programming Companion",
            description: "Master algorithmic thinking and climb the ratings ladder with AI-powered insights and comprehensive tracking. Start your journey to coding excellence.",
            systemImage: "star.fill",
            accentColor: Color.blue,
            gradientColors: [Color.blue, Color.purple]
        ),
        OnboardingPage(
            title: "Track Your Progress",
            subtitle: "Real-time Performance Analytics",
            description: "Monitor your Codeforces submissions, analyze your strengths and weaknesses, and track your rating growth over time with beautiful visualizations.",
            systemImage: "chart.line.uptrend.xyaxis",
            accentColor: Color.green,
            gradientColors: [Color.green, Color.mint]
        ),
        OnboardingPage(
            title: "AI-Powered Learning",
            subtitle: "Personalized Practice Suggestions",
            description: "Get intelligent recommendations on topics to focus on, problems to solve, and strategies to improve based on your unique coding patterns and performance.",
            systemImage: "brain.head.profile",
            accentColor: Color.purple,
            gradientColors: [Color.purple, Color.pink]
        ),
        OnboardingPage(
            title: "Contest & Community",
            subtitle: "Stay Competition Ready",
            description: "Never miss upcoming contests, compare with friends on leaderboards, and maintain your solving streak with daily goals and achievements.",
            systemImage: "trophy.fill",
            accentColor: Color.orange,
            gradientColors: [Color.orange, Color.red]
        ),
        OnboardingPage(
            title: "Smart Problem Management",
            subtitle: "Organize Your Learning",
            description: "Save problems for later review, take notes on solutions, and build your personal library of solved problems with detailed insights and progress tracking.",
            systemImage: "bookmark.fill",
            accentColor: Color.indigo,
            gradientColors: [Color.indigo, Color.blue]
        )
    ]
    
    var body: some View {
        ZStack {
            // Simple background
            colorThemeManager.current.background
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced content with gesture support
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: currentPage == index)
                            .environmentObject(colorThemeManager)
                            .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragOffset = gesture.translation.width
                        }
                        .onEnded { gesture in
                            let threshold: CGFloat = 50
                            let translationX = gesture.translation.width
                            if translationX > threshold && currentPage > 0 {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    currentPage -= 1
                                }
                            } else if translationX < -threshold && currentPage < pages.count - 1 {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            }
                            dragOffset = 0
                        }
                )
                
                // Enhanced bottom controls with better spacing
                VStack(spacing: 32) {
                    // Improved page indicator with progress animation
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            if index == currentPage {
                                Capsule()
                                    .fill(pages[currentPage].accentColor)
                                    .frame(width: 32, height: 8)
                                    .shadow(color: pages[currentPage].accentColor.opacity(0.6), radius: 4, y: 2)
                            } else {
                                Circle()
                                    .fill(colorThemeManager.current.text.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentPage)
                    
                    // Simple navigation - only button on last screen
                    HStack {
                        Spacer()
                        
                        if currentPage == pages.count - 1 {
                            Button(action: {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                                    showGetStarted = true
                                }
                                
                                // Haptic feedback
                                #if os(iOS)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                #endif
                                
                                // Delay to show animation, then dismiss
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    UserDefaults.standard.set(false, forKey: "isFirstLaunch")
                                    isFirstLaunch = false
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "rocket.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Get Started")
                                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(pages[currentPage].accentColor)
                                )
                                .scaleEffect(showGetStarted ? 1.05 : 1.0)
                                .opacity(showGetStarted ? 0.9 : 1.0)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateContent = true
            }
            
            // Auto-advance pages with a longer interval for better reading
            Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { timer in
                if currentPage < pages.count - 1 {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
        .onChange(of: currentPage) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                animateContent = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateContent = true
                }
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var iconScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0
    @State private var titleOffset: CGFloat = 50
    @State private var subtitleOffset: CGFloat = 30
    @State private var descriptionOffset: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Enhanced icon with layered animation effects
                ZStack {
                    // Outer glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    page.accentColor.opacity(0.3),
                                    page.accentColor.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isActive ? 1.0 : 0.8)
                    
                    // Middle ring
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: page.gradientColors.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(iconScale)
                    
                    // Inner circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: page.gradientColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(iconScale * 0.8)
                    
                    // Icon with enhanced styling
                    Image(systemName: page.systemImage)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: page.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                        .shadow(color: page.accentColor.opacity(0.3), radius: 8, y: 4)
                }
                .frame(height: 240)
                
                Spacer().frame(height: 40)
                
                // Enhanced content with staggered animations
                VStack(spacing: 24) {
                    // Title with custom font and better spacing
                    Text(page.title)
                        .font(.custom("TTPhobosTrial-Bold", size: 36))
                        .foregroundStyle(colorThemeManager.current.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .lineSpacing(4)
                        .offset(y: titleOffset)
                        .opacity(contentOpacity)
                        .padding(.horizontal, 24)
                    
                    // Subtitle with accent styling
                    Text(page.subtitle)
                        .font(.custom("TTPhobosTrial-DemiBold", size: 20))
                        .foregroundStyle(page.accentColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .lineSpacing(2)
                        .offset(y: subtitleOffset)
                        .opacity(contentOpacity)
                        .padding(.horizontal, 32)
                    
                    // Description with improved readability
                    Text(page.description)
                        .font(.custom("TTPhobosTrial-Regular", size: 17))
                        .foregroundStyle(colorThemeManager.current.text.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .lineSpacing(6)
                        .tracking(0.3)
                        .offset(y: descriptionOffset)
                        .opacity(contentOpacity)
                        .padding(.horizontal, 40)
                        .frame(maxHeight: 120)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                startAnimations()
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startAnimations()
                }
            }
        }
    }
    
    private func startAnimations() {
        // Reset all states
        iconScale = 0.5
        contentOpacity = 0
        titleOffset = 50
        subtitleOffset = 30
        descriptionOffset = 20
        
        // Staggered animation sequence
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            titleOffset = 0
            contentOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            subtitleOffset = 0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7)) {
            descriptionOffset = 0
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let accentColor: Color
    let gradientColors: [Color]
}

// MARK: - Preview
#Preview {
    OnboardingView(isFirstLaunch: .constant(true))
        .environmentObject(ColorThemeManager())
        .preferredColorScheme(.dark)
}
