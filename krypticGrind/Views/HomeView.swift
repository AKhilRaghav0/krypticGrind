//
//  HomeView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI
import Foundation
import VisionKit
import Vision
import PhotosUI

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
    
    // Camera and AI analysis states
    @State private var showingImagePicker = false
    @State private var showingDocumentCamera = false
    @State private var selectedImage: UIImage?
    @State private var extractedText = ""
    @State private var showingAIAnalysis = false
    @State private var aiAnalysisResult = ""
    @State private var isAnalyzingImage = false
    @State private var showingCameraMenu = false
    @State private var showingProcessingOverlay = false
    @State private var isCameraActive = false
    @State private var showingFullAnalysis = false
    
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
                
                // Processing overlay with Apple Intelligence style blur
                if showingProcessingOverlay {
                    ProcessingOverlay()
                        .transition(.opacity)
                        .zIndex(2)
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
                            
                            // Camera/Scanner button
                            Button(action: { showingCameraMenu = true }) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 20))
                                    .foregroundColor(colorThemeManager.current.accent)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(colorThemeManager.current.tabBar.opacity(0.6))
                                    )
                            }
                            
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
                            AISuggestionsCard(
                                suggestions: [
                                    "Practice dynamic programming",
                                    "Focus on graph algorithms",
                                    "Master binary search",
                                    "Learn segment trees"
                                ],
                                onSuggestionTapped: { suggestion in
                                    // Handle suggestion tap
                                }
                            )
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
            .sheet(isPresented: $showingCameraMenu) {
                RPGCameraPickerSheet(
                    onTakePhoto: {
                        showingCameraMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if !isCameraActive {
                                isCameraActive = true
                                showingDocumentCamera = true
                            }
                        }
                    },
                    onChooseFromGallery: {
                        showingCameraMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if !isCameraActive {
                                isCameraActive = true
                                showingImagePicker = true
                            }
                        }
                    }
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingDocumentCamera) {
                DocumentCameraView { image in
                    selectedImage = image
                    showingDocumentCamera = false
                    isCameraActive = false
                    showingProcessingOverlay = true
                    extractTextFromImage(image)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    selectedImage = image
                    showingImagePicker = false
                    isCameraActive = false
                    showingProcessingOverlay = true
                    extractTextFromImage(image)
                }
            }
            .fullScreenCover(isPresented: $showingAIAnalysis) {
                AIAnalysisFullScreenView(
                    extractedText: extractedText,
                    analysisResult: $aiAnalysisResult,
                    isAnalyzing: $isAnalyzingImage,
                    selectedImage: selectedImage,
                    onAnalyze: analyzeTextWithGemini
                )
            }        .sheet(isPresented: $showingFullAnalysis) {
            MarkdownDisplayView(content: aiAnalysisResult.isEmpty ? """
                # 🔍 Analysis Status
                
                ## Current Status
                No analysis available yet.
                
                ## How to get analysis:
                1. **Tap the camera button** 📸 in the top right
                2. **Take a photo** or **choose from gallery**
                3. **Wait for text extraction** (a few seconds)
                4. **AI analysis will start automatically**
                
                ## What you'll get:
                - 🎯 Problem type identification
                - 🧠 Core concepts needed
                - ⚡ Difficulty assessment
                - 🗺️ Step-by-step strategy
                - 📚 Prerequisites to study
                - 🎯 Practice recommendations
                - ⚠️ Common pitfalls to avoid
                
                The AI Strategy Guide helps you **think like a pro** without giving away the solution!
                """ : aiAnalysisResult)
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
    
    // MARK: - Text Extraction from Image
    private func extractTextFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            showingProcessingOverlay = false
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                DispatchQueue.main.async {
                    self.showingProcessingOverlay = false
                }
                return
            }
            
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                self.extractedText = recognizedStrings.joined(separator: "\n")
                print("Extracted text: \(self.extractedText)")
                if !self.extractedText.isEmpty {
                    // Keep processing overlay until AI analysis starts
                    self.showingAIAnalysis = true
                    Task {
                        await self.analyzeTextWithGemini()
                    }
                } else {
                    self.showingProcessingOverlay = false
                    print("No text extracted from image")
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
                DispatchQueue.main.async {
                    self.showingProcessingOverlay = false
                }
            }
        }
    }
    
    // MARK: - AI Analysis with Gemini
    private func analyzeTextWithGemini() async {
        guard !extractedText.isEmpty else {
            showingProcessingOverlay = false
            return
        }
        
        isAnalyzingImage = true
        
        // Hide processing overlay once AI analysis screen is shown
        DispatchQueue.main.async {
            self.showingProcessingOverlay = false
        }
        
        let prompt = """
        You are an expert competitive programming mentor. A user has extracted text from an image that appears to be a coding problem or algorithm concept. 

        Your task: Analyze the problem and provide a **strategic approach guide** - teach them HOW to think about and solve it, but DO NOT provide any code or direct solutions.

        Text extracted from image:
        ```
        \(extractedText)
        ```

        Please provide your analysis in this format using proper markdown:

        # Problem Analysis

        ## 🎯 Problem Type
        [Identify what type of problem this is - e.g., Dynamic Programming, Graph Theory, Greedy, etc.]

        ## 🧠 Core Concepts Required
        [List the key algorithms, data structures, or mathematical concepts needed]

        ## ⚡ Difficulty Assessment
        **Rating**: [Beginner/Intermediate/Advanced/Expert]
        **Estimated Codeforces Rating**: [Give a rating range like 1200-1400]

        ## 🗺️ Strategic Approach

        ### Step 1: Understanding the Problem
        [How to break down and understand what's being asked]

        ### Step 2: Pattern Recognition
        [What patterns or similarities to other problems should they notice]

        ### Step 3: Solution Strategy
        [High-level approach - what algorithm/technique to use and why]

        ### Step 4: Implementation Tips
        [Key things to consider when coding, common pitfalls to avoid]

        ## 📚 Prerequisites to Study
        [Topics they should master before attempting this problem]

        ## 🎯 Practice Path
        [Suggest 2-3 easier problems they should solve first to build up to this]

        ## ⚠️ Common Pitfalls
        [Typical mistakes beginners make with this type of problem]

        Remember: Focus on **thinking process** and **problem-solving strategy**, not code implementation!
        """
        
        do {
            // Use the existing GeminiService method
            let response = try await GeminiService.shared.callGeminiAPI(prompt: prompt)
            
            await MainActor.run {
                self.aiAnalysisResult = response.isEmpty ? "# Analysis Complete\n\nI received your request but the analysis result was empty. This might be due to API limitations or network issues. Please try again." : response
                self.isAnalyzingImage = false
                print("AI Analysis completed with result length: \(response.count)")
            }
        } catch {
            await MainActor.run {
                self.aiAnalysisResult = """
                # Analysis Error
                
                ## ⚠️ Unable to Complete Analysis
                
                I encountered an issue while analyzing your problem: \(error.localizedDescription)
                
                ## 🔄 What you can try:
                - Check your internet connection
                - Try capturing the image again
                - Make sure the image contains clear, readable text
                - The AI service might be temporarily unavailable
                
                ## 💡 Manual Analysis Tips:
                - Identify what type of problem it is (DP, Graph, Array, etc.)
                - Look for patterns and constraints
                - Think about the time complexity requirements
                - Consider edge cases
                """
                self.isAnalyzingImage = false
                print("AI Analysis failed with error: \(error)")
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
                subtitle: "participated",
                icon: "trophy.fill",
                color: Color.orange
            )
            
            ModernStatCard(
                title: "Submissions",
                value: "\(cfService.recentSubmissions.count)",
                subtitle: "total",
                icon: "doc.text.fill",
                color: colorThemeManager.current.accent
            )
            
            ModernStatCard(
                title: "Accepted",
                value: "\(cfService.recentSubmissions.acceptedSubmissions().count)",
                subtitle: "solved",
                icon: "checkmark.circle.fill",
                color: Color.green
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

// MARK: - Enhanced Streak Card
struct EnhancedStreakCard: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var currentStreak: Int {
        cfService.recentSubmissions.calculateStreak()
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔥 Daily Streak")
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
            
            // Fire streak visualization
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    Text("🔥")
                        .font(.system(size: 24))
                        .opacity(index < min(currentStreak, 5) ? 1.0 : 0.3)
                        .scaleEffect(index < min(currentStreak, 5) ? 1.0 : 0.8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

// MARK: - GitHub Style Streak Grid
struct GitHubStyleStreakGrid: View {
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Activity Grid")
                .font(.custom("TTPhobosTrial-Bold", size: 16))
                .foregroundColor(colorThemeManager.current.text)
            
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(getLast91Days(), id: \.self) { date in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(getActivityColor(intensity: getActivityCount(for: date)))
                        .frame(width: 12, height: 12)
                }
            }
            
            HStack {
                Text("Less")
                    .font(.caption)
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(getActivityColor(intensity: level))
                            .frame(width: 10, height: 10)
                    }
                }
                
                Text("More")
                    .font(.caption)
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorThemeManager.current.surface.opacity(0.6))
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
        case 0: return colorThemeManager.current.text.opacity(0.05)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        default: return Color.green
        }
    }
}

// MARK: - User Stats Overview
struct UserStatsOverview: View {
    let user: CFUser
    @StateObject private var cfService = CFService.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("⚡ Power Stats")
                .font(.custom("TTPhobosTrial-Bold", size: 18))
                .foregroundColor(colorThemeManager.current.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatItemCard(
                    icon: "🏆",
                    title: "Rating",
                    value: "\(user.rating)",
                    color: Color.ratingColor(for: user.rating)
                )
                
                StatItemCard(
                    icon: "📈",
                    title: "Max Rating",
                    value: "\(user.maxRating)",
                    color: Color.ratingColor(for: user.maxRating)
                )
                
                StatItemCard(
                    icon: "⚔️",
                    title: "Contests",
                    value: "\(cfService.ratingHistory.count)",
                    color: Color.orange
                )
                
                StatItemCard(
                    icon: "✅",
                    title: "Solved",
                    value: "\(cfService.recentSubmissions.filter { $0.isAccepted }.count)",
                    color: Color.green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

struct StatItemCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(value)
                .font(.custom("TTPhobosTrial-Bold", size: 20))
                .foregroundColor(color)
            
            Text(title)
                .font(.custom("TTPhobosTrial-Regular", size: 12))
                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorThemeManager.current.background.opacity(0.5))
        )
    }
}

// MARK: - Empty Contest Card
struct EmptyContestCard: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text("🏁")
                .font(.system(size: 40))
                .opacity(0.6)
            
            Text("No Upcoming Contests")
                .font(.custom("TTPhobosTrial-Bold", size: 18))
                .foregroundColor(colorThemeManager.current.text)
            
            Text("Check back later for new battles!")
                .font(.custom("TTPhobosTrial-Regular", size: 14))
                .foregroundColor(colorThemeManager.current.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.surface.opacity(0.6))
        )
    }
}

// MARK: - Enhanced Settings Sheet
struct EnhancedSettingsSheet: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("⚙️ Settings")
                    .font(.custom("TTPhobosTrial-Bold", size: 24))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text("Customize your battle preferences")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .font(.custom("TTPhobosTrial-Bold", size: 16))
                .foregroundColor(.white)
                .padding()
                .background(colorThemeManager.current.accent)
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - RPG Camera Picker Sheet
struct RPGCameraPickerSheet: View {
    let onTakePhoto: () -> Void
    let onChooseFromGallery: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("🏰 Capture Ancient Text")
                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text("Extract mystical knowledge from scrolls")
                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
            }
            
            VStack(spacing: 16) {
                RPGActionButton(
                    icon: "�",
                    title: "Scan Ancient Scroll",
                    subtitle: "Use mystical camera",
                    color: colorThemeManager.current.accent,
                    action: onTakePhoto
                )
                
                RPGActionButton(
                    icon: "�️",
                    title: "Choose from Grimoire",
                    subtitle: "Select from collection",
                    color: .blue,
                    action: onChooseFromGallery
                )
            }
            
            Spacer()
        }
        .padding(24)
        .background(colorThemeManager.current.background)
    }
}

// MARK: - RPG Action Button
struct RPGActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    Text(subtitle)
                        .font(.custom("TTPhobosTrial-Regular", size: 12))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.1),
                                color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Document Camera View
struct DocumentCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                onImageCaptured(image)
            }
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - RPG Navigation Bar
struct RPGNavigationBar: View {
    let title: String
    let subtitle: String?
    let leftAction: () -> Void
    let leftIcon: String
    let rightAction: (() -> Void)?
    let rightIcon: String?
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    init(
        title: String,
        subtitle: String? = nil,
        leftAction: @escaping () -> Void,
        leftIcon: String = "arrow.left",
        rightAction: (() -> Void)? = nil,
        rightIcon: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leftAction = leftAction
        self.leftIcon = leftIcon
        self.rightAction = rightAction
        self.rightIcon = rightIcon
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Left button
                Button(action: leftAction) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        colorThemeManager.current.surface.opacity(0.8),
                                        colorThemeManager.current.surface.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: leftIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colorThemeManager.current.accent)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Title section
                VStack(spacing: 2) {
                    Text(title)
                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                        .foregroundColor(colorThemeManager.current.text)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("TTPhobosTrial-Regular", size: 12))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Right button (optional)
                if let rightAction = rightAction, let rightIcon = rightIcon {
                    Button(action: rightAction) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            colorThemeManager.current.surface.opacity(0.8),
                                            colorThemeManager.current.surface.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                                )
                            
                            Image(systemName: rightIcon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colorThemeManager.current.accent)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        colorThemeManager.current.background.opacity(0.8),
                                        colorThemeManager.current.background.opacity(0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            
            // Bottom border
            Rectangle()
                .fill(colorThemeManager.current.accent.opacity(0.1))
                .frame(height: 1)
        }
    }
}

// MARK: - AI Analysis Full Screen View
struct AIAnalysisFullScreenView: View {
    let extractedText: String
    @Binding var analysisResult: String
    @Binding var isAnalyzing: Bool
    let selectedImage: UIImage?
    let onAnalyze: () async -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingFullAnalysis = false
    
    var body: some View {
        ZStack {
            colorThemeManager.current.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom RPG Navigation Bar
                RPGNavigationBar(
                    title: "Problem Analysis",
                    subtitle: "Mystical Text Recognition",
                    leftAction: {
                        dismiss()
                    },
                    leftIcon: "arrow.left"
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with image preview
                        if let image = selectedImage {
                            VStack(spacing: 12) {
                                Text("📸 Captured Problem")
                                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                                    .foregroundColor(colorThemeManager.current.text)
                                
                                ZStack {
                                    // Animated meshnet gradient background
                                    AnimatedMeshGradient()
                                        .frame(height: 200)
                                        .cornerRadius(16)
                                    
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 180)
                                        .cornerRadius(12)
                                        .shadow(radius: 8)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Extracted text section
                        if !extractedText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("📝")
                                        .font(.system(size: 16))
                                    Text("Extracted Text")
                                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                                        .foregroundColor(colorThemeManager.current.text)
                                    Spacer()
                                }
                                
                                Text(extractedText)
                                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                                    .foregroundColor(colorThemeManager.current.text.opacity(0.8))
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorThemeManager.current.surface.opacity(0.6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // AI Analysis section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("🤖")
                                    .font(.system(size: 20))
                                Text("AI Strategy Guide")
                                    .font(.custom("TTPhobosTrial-Bold", size: 20))
                                    .foregroundColor(colorThemeManager.current.text)
                                Spacer()
                            }
                            
                            if isAnalyzing {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: colorThemeManager.current.accent))
                                        .scaleEffect(1.2)
                                    
                                    Text("🧠 Processing problem...")
                                        .font(.custom("TTPhobosTrial-Regular", size: 16))
                                        .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                                    
                                    Text("Preparing strategic insights...")
                                        .font(.custom("TTPhobosTrial-Regular", size: 14))
                                        .foregroundColor(colorThemeManager.current.text.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                // Always show the button for debugging
                                Button(action: {
                                    // Add haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    // Add scale animation
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        showingFullAnalysis = true
                                    }
                                }) {
                                    RPGAnalysisCard(
                                        isReady: !analysisResult.isEmpty
                                    ) {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                        
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            showingFullAnalysis = true
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .sheet(isPresented: $showingFullAnalysis) {
            MarkdownDisplayView(content: analysisResult.isEmpty ? """
                # 🔍 Analysis Status
                
                ## Current Status
                No analysis available yet.
                
                ## How to get analysis:
                1. **Tap the test button** 🧪 above to trigger analysis
                2. **Wait for AI processing** (may take 10-30 seconds)
                3. **Results will appear here** automatically
                
                ## What you'll get:
                - 🎯 Problem type identification
                - 🧠 Core concepts needed
                - ⚡ Difficulty assessment
                - 🗺️ Step-by-step strategy
                - 📚 Prerequisites to study
                - 🎯 Practice recommendations
                - ⚠️ Common pitfalls to avoid
                
                The AI Strategy Guide helps you **think like a pro** without giving away the solution!
                """ : analysisResult)
        }
    }
}

// MARK: - Markdown Display View
struct MarkdownDisplayView: View {
    let content: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            colorThemeManager.current.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom RPG Navigation Bar
                RPGNavigationBar(
                    title: "Strategy Guide",
                    subtitle: "AI-Powered Analysis",
                    leftAction: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            animateIn = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dismiss()
                        }
                    },
                    leftIcon: "arrow.left"
                )
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : -20)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        AdvancedMarkdownText(content)
                            .padding(20)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 30)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Advanced Markdown Text View
struct AdvancedMarkdownText: View {
    let content: String
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var displayedContent = ""
    @State private var isAnimating = false
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseAdvancedMarkdown(displayedContent), id: \.id) { element in
                switch element.type {
                case .header1:
                    Text(element.text)
                        .font(.custom("TTPhobosTrial-Bold", size: 24))
                        .foregroundColor(colorThemeManager.current.text)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                case .header2:
                    Text(element.text)
                        .font(.custom("TTPhobosTrial-Bold", size: 20))
                        .foregroundColor(colorThemeManager.current.accent)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                        
                case .header3:
                    Text(element.text)
                        .font(.custom("TTPhobosTrial-DemiBold", size: 18))
                        .foregroundColor(colorThemeManager.current.text)
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                        
                case .bold:
                    Text(parseInlineFormatting(element.text))
                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                        .foregroundColor(colorThemeManager.current.text)
                        .padding(.vertical, 2)
                        
                case .italic:
                    Text(parseInlineFormatting(element.text))
                        .font(.custom("TTPhobosTrial-Italic", size: 16))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.8))
                        .padding(.vertical, 2)
                        
                case .code:
                    Text(element.text)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(colorThemeManager.current.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colorThemeManager.current.surface.opacity(0.6))
                        )
                        
                case .text:
                    Text(parseInlineFormatting(element.text))
                        .font(.custom("TTPhobosTrial-Regular", size: 16))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.9))
                        .padding(.vertical, 2)
                        
                case .listItem:
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.custom("TTPhobosTrial-Bold", size: 16))
                            .foregroundColor(colorThemeManager.current.accent)
                        
                        Text(parseInlineFormatting(element.text))
                            .font(.custom("TTPhobosTrial-Regular", size: 16))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.9))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .onAppear {
            startTypewriterAnimation()
        }
    }
    
    private func startTypewriterAnimation() {
        isAnimating = true
        let characters = Array(content)
        var currentIndex = 0
        
        // Faster, smoother typewriter effect
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedContent = String(characters[0...currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                isAnimating = false
            }
        }
    }
    
    private func parseAdvancedMarkdown(_ text: String) -> [AdvancedMarkdownElement] {
        var elements: [AdvancedMarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                continue
            }
            
            if trimmed.hasPrefix("# ") {
                elements.append(AdvancedMarkdownElement(id: index, type: .header1, text: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("## ") {
                elements.append(AdvancedMarkdownElement(id: index, type: .header2, text: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("### ") {
                elements.append(AdvancedMarkdownElement(id: index, type: .header3, text: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") && trimmed.count > 4 {
                elements.append(AdvancedMarkdownElement(id: index, type: .bold, text: String(trimmed.dropFirst(2).dropLast(2))))
            } else if trimmed.hasPrefix("*") && trimmed.hasSuffix("*") && trimmed.count > 2 && !trimmed.hasPrefix("**") {
                elements.append(AdvancedMarkdownElement(id: index, type: .italic, text: String(trimmed.dropFirst(1).dropLast(1))))
            } else if trimmed.hasPrefix("`") && trimmed.hasSuffix("`") && trimmed.count > 2 {
                elements.append(AdvancedMarkdownElement(id: index, type: .code, text: String(trimmed.dropFirst(1).dropLast(1))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                elements.append(AdvancedMarkdownElement(id: index, type: .listItem, text: String(trimmed.dropFirst(2))))
            } else {
                elements.append(AdvancedMarkdownElement(id: index, type: .text, text: trimmed))
            }
        }
        
        return elements
    }
    
    private func parseInlineFormatting(_ text: String) -> String {
        // Simple inline formatting - could be enhanced further
        return text
    }
}

// MARK: - Advanced Markdown Element Model
struct AdvancedMarkdownElement {
    let id: Int
    let type: AdvancedMarkdownType
    let text: String
    
    enum AdvancedMarkdownType {
        case header1, header2, header3, bold, italic, code, text, listItem
    }
}

// MARK: - Animated Mesh Gradient
struct AnimatedMeshGradient: View {
    @State private var animate = false
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    colorThemeManager.current.accent.opacity(0.6),
                    colorThemeManager.current.accent.opacity(0.3),
                    Color.blue.opacity(0.4),
                    Color.purple.opacity(0.3)
                ],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )
            .blur(radius: 8)
            
            // Mesh overlay effect
            Canvas { context, size in
                let gridSize: CGFloat = 20
                let rows = Int(size.height / gridSize)
                let cols = Int(size.width / gridSize)
                
                context.stroke(
                    Path { path in
                        for i in 0...rows {
                            let y = CGFloat(i) * gridSize
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        
                        for i in 0...cols {
                            let x = CGFloat(i) * gridSize
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        }
                    },
                    with: .color(colorThemeManager.current.accent.opacity(animate ? 0.3 : 0.1)),
                    lineWidth: 1
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlay: View {
    @State private var isAnimating = false
    @State private var meshAnimating = false
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            // Base material background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Mesh gradients in corners
            GeometryReader { geometry in
                // Top-left corner mesh
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                colorThemeManager.current.accent.opacity(meshAnimating ? 0.4 : 0.2),
                                colorThemeManager.current.accent.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .position(x: -50, y: -50)
                    .blur(radius: 20)
                
                // Top-right corner mesh
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(meshAnimating ? 0.3 : 0.15),
                                Color.purple.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .position(x: geometry.size.width + 30, y: -30)
                    .blur(radius: 15)
                
                // Bottom-left corner mesh
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(meshAnimating ? 0.35 : 0.18),
                                Color.pink.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .position(x: -20, y: geometry.size.height + 20)
                    .blur(radius: 18)
                
                // Bottom-right corner mesh
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                colorThemeManager.current.accent.opacity(meshAnimating ? 0.25 : 0.12),
                                Color.orange.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                    .position(x: geometry.size.width + 40, y: geometry.size.height + 40)
                    .blur(radius: 22)
            }
            .ignoresSafeArea()
            
            // Central content
            VStack(spacing: 24) {
                // Animated processing icon with mesh effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    colorThemeManager.current.accent.opacity(0.3),
                                    colorThemeManager.current.accent.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    Image(systemName: "cpu")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(colorThemeManager.current.accent)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .shadow(color: colorThemeManager.current.accent.opacity(0.6), radius: 10)
                }
                
                VStack(spacing: 8) {
                    Text("⚡ AI Strategy Guide...")
                        .font(.custom("TTPhobosTrial-Bold", size: 22))
                        .foregroundColor(colorThemeManager.current.text)
                        .shadow(color: colorThemeManager.current.accent.opacity(0.3), radius: 5)
                    
                    Text("Analyzing problem patterns...")
                        .font(.custom("TTPhobosTrial-Regular", size: 16))
                        .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                }
                
                // Animated progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(colorThemeManager.current.accent)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                meshAnimating = true
            }
        }
    }
}

// MARK: - Sword Fighting Overlay
struct SwordFightingOverlay: View {
    @State private var swordPosition: CGFloat = -200
    @State private var sparkles: [SparkleEffect] = []
    @State private var showVictoryText = false
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .ignoresSafeArea()
            
            Image(systemName: "sword.fill")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(colorThemeManager.current.accent)
                .rotationEffect(.degrees(45))
                .offset(x: swordPosition)
                .shadow(color: colorThemeManager.current.accent, radius: 10)
            
            ForEach(sparkles, id: \.id) { sparkle in
                Circle()
                    .fill(sparkle.color)
                    .frame(width: sparkle.size, height: sparkle.size)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .opacity(sparkle.opacity)
                    .scaleEffect(sparkle.scale)
            }
            
            if showVictoryText {
                VStack {
                    Text("💎 QUEST COMPLETE!")
                        .font(.custom("TTPhobosTrial-Bold", size: 28))
                        .foregroundColor(.white)
                        .shadow(color: colorThemeManager.current.accent, radius: 5)
                    
                    Text("XP +50")
                        .font(.custom("TTPhobosTrial-Regular", size: 18))
                        .foregroundColor(colorThemeManager.current.accent)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            startSwordAnimation()
        }
    }
    
    private func startSwordAnimation() {
        withAnimation(.easeInOut(duration: 0.8)) {
            swordPosition = 200
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            generateSparkles()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring()) {
                showVictoryText = true
            }
        }
    }
    
    private func generateSparkles() {
        for _ in 0..<15 {
            let sparkle = SparkleEffect(
                id: UUID(),
                x: CGFloat.random(in: -100...100),
                y: CGFloat.random(in: -50...50),
                size: CGFloat.random(in: 4...12),
                color: [Color.yellow, Color.orange, Color.red, Color.purple].randomElement()!,
                opacity: 1.0,
                scale: 1.0
            )
            sparkles.append(sparkle)
        }
        
        withAnimation(.easeOut(duration: 1.5)) {
            for i in sparkles.indices {
                sparkles[i].opacity = 0
                sparkles[i].scale = 0.5
                sparkles[i].y -= 30
            }
        }
    }
}

struct SparkleEffect {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    var opacity: Double
    var scale: CGFloat
}

// MARK: - AI Suggestions Card
struct AISuggestionsCard: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var animateGradient = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(colorThemeManager.current.accent)
                
                Text("⚡ AI Insights")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    Button(action: { onSuggestionTapped(suggestion) }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(suggestion)
                                .font(.custom("TTPhobosTrial-Regular", size: 14))
                                .foregroundColor(colorThemeManager.current.text)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorThemeManager.current.tabBar)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorThemeManager.current.tabBar)
        )
    }
}

// MARK: - Modern Stat Card
struct ModernStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var animateValue = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(color)
                    )
                
                Spacer()
            }
            
            Text(value)
                .font(.custom("TTPhobosTrial-Bold", size: 24))
                .foregroundColor(colorThemeManager.current.text)
                .scaleEffect(animateValue ? 1.05 : 1.0)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("TTPhobosTrial-Medium", size: 14))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text(subtitle)
                    .font(.custom("TTPhobosTrial-Regular", size: 12))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorThemeManager.current.tabBar)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateValue = true
            }
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

// MARK: - RPG Analysis Card
struct RPGAnalysisCard: View {
    let isReady: Bool
    let onTap: () -> Void
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var isGlowing = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Dark mystical background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.85),
                                Color.black.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isReady ? 
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [colorThemeManager.current.accent.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                // Content
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        // Mystical icon
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: isReady ? [
                                            Color.cyan.opacity(0.6),
                                            Color.clear
                                        ] : [
                                            colorThemeManager.current.accent.opacity(0.4),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 25
                                    )
                                )
                                .frame(width: 45, height: 45)
                                .scaleEffect(isGlowing ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isGlowing)
                            
                            Image(systemName: isReady ? "sparkles" : "book.closed")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(isReady ? Color.cyan : colorThemeManager.current.accent)
                                .shadow(color: isReady ? Color.cyan.opacity(0.8) : Color.clear, radius: 6)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("🔮 View Strategy Guide")
                                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(isReady ? Color.cyan : colorThemeManager.current.accent)
                            }
                            
                            Text(isReady ? "⚡ Mystical analysis ready!" : "🏺 Awaiting ancient wisdom...")
                                .font(.custom("TTPhobosTrial-Regular", size: 14))
                                .foregroundColor(isReady ? Color.cyan.opacity(0.9) : Color.gray)
                        }
                    }
                    
                    // Magical progress crystals
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    index < (isReady ? 5 : 0) ? 
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 6)
                                .shadow(color: isReady ? Color.cyan.opacity(0.5) : Color.clear, radius: 3)
                        }
                    }
                }
                .padding(20)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isGlowing = true
        }
        .scaleEffect(isReady ? 1.02 : 1.0)
        .shadow(color: isReady ? Color.cyan.opacity(0.3) : Color.clear, radius: 15)
        .animation(.easeInOut(duration: 0.3), value: isReady)
    }
}

#Preview {
    HomeView()
}
