//
//  DungeonLeaderboardView.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

struct DungeonLeaderboardView: View {
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @StateObject private var leaderboardManager = LeaderboardManager.shared
    @State private var showingAddHandle = false
    @State private var searchText = ""
    
    var filteredHandles: [LeaderboardHandle] {
        if searchText.isEmpty {
            return leaderboardManager.handles
        }
        return leaderboardManager.handles.filter { handle in
            handle.handle.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var sortedHandles: [LeaderboardHandle] {
        filteredHandles.sorted { handle1, handle2 in
            // Sort by rating (descending), then by problems solved (descending)
            if handle1.rating != handle2.rating {
                return handle1.rating > handle2.rating
            }
            return handle1.problemsSolved > handle2.problemsSolved
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Search and Add Section
                HallOfFameHeader(searchText: $searchText, showingAddHandle: $showingAddHandle)
                    .padding(.horizontal, 20)
                
                if leaderboardManager.handles.isEmpty {
                    EmptyHallOfFameView(showingAddHandle: $showingAddHandle)
                        .padding(.horizontal, 20)
                } else {
                    // Champion Podium (Top 3)
                    if sortedHandles.count >= 3 {
                        ChampionPodium(champions: Array(sortedHandles.prefix(3)))
                            .padding(.horizontal, 20)
                    }
                    
                    // Warriors List (Rest)
                    if sortedHandles.count > 3 {
                        WarriorsList(warriors: Array(sortedHandles.dropFirst(3)))
                            .padding(.horizontal, 20)
                    } else if sortedHandles.count > 0 && sortedHandles.count < 3 {
                        // If we have less than 3, show them in the warriors list
                        WarriorsList(warriors: sortedHandles)
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer().frame(height: 50)
            }
            .padding(.top, 20)
        }
        .refreshable {
            await leaderboardManager.refreshAllHandles()
        }
        .sheet(isPresented: $showingAddHandle) {
            DungeonAddHandleSheet()
        }
        .task {
            await leaderboardManager.refreshAllHandles()
        }
    }
}

// MARK: - Hall of Fame Header
struct HallOfFameHeader: View {
    @Binding var searchText: String
    @Binding var showingAddHandle: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                        .font(.system(size: 16))
                    
                    TextField("Search warriors...", text: $searchText)
                        .font(.custom("TTPhobosTrial-Regular", size: 16))
                        .foregroundColor(colorThemeManager.current.text)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorThemeManager.current.tabBar.opacity(0.8))
                        .stroke(colorThemeManager.current.accent.opacity(0.2), lineWidth: 1)
                )
                
                // Add Warrior Button
                Button(action: {
                    showingAddHandle = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(colorThemeManager.current.accent)
                    )
                }
            }
        }
    }
}

// MARK: - Champion Podium
struct ChampionPodium: View {
    let champions: [LeaderboardHandle]
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🏛️ Champion Podium")
                .font(.custom("TTPhobosTrial-Bold", size: 20))
                .foregroundColor(colorThemeManager.current.text)
            
            HStack(alignment: .bottom, spacing: 20) {
                // Second Place
                if champions.count > 1 {
                    ChampionCard(champion: champions[1], rank: 2, height: 100)
                        .frame(maxWidth: .infinity)
                }
                
                // First Place (Tallest)
                if champions.count > 0 {
                    ChampionCard(champion: champions[0], rank: 1, height: 120)
                        .frame(maxWidth: .infinity)
                }
                
                // Third Place
                if champions.count > 2 {
                    ChampionCard(champion: champions[2], rank: 3, height: 80)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: .yellow.opacity(0.1), radius: 12, y: 4)
        )
    }
}

struct ChampionCard: View {
    let champion: LeaderboardHandle
    let rank: Int
    let height: CGFloat
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    private var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "👑"
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return colorThemeManager.current.accent
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Rank Icon
            Text(rankIcon)
                .font(.system(size: rank == 1 ? 28 : 22))
            
            // Avatar
            Circle()
                .fill(colorThemeManager.current.text.opacity(0.2))
                .overlay {
                    Image(systemName: rank == 1 ? "crown.fill" : "person.fill")
                        .foregroundColor(rank == 1 ? .yellow : colorThemeManager.current.text.opacity(0.6))
                        .font(.system(size: rank == 1 ? 18 : 14))
                }
            .frame(width: rank == 1 ? 54 : 44, height: rank == 1 ? 54 : 44)
            .overlay(
                Circle()
                    .stroke(rankColor, lineWidth: rank == 1 ? 3 : 2)
            )
            .shadow(color: rankColor.opacity(0.3), radius: rank == 1 ? 6 : 4, x: 0, y: 2)
            
            // Info
            VStack(spacing: 4) {
                Text(champion.handle)
                    .font(.custom("TTPhobosTrial-Bold", size: rank == 1 ? 16 : 14))
                    .foregroundColor(colorThemeManager.current.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
                
                Text("\(champion.rating)")
                    .font(.custom("TTPhobosTrial-DemiBold", size: rank == 1 ? 14 : 12))
                    .foregroundColor(rankColor)
                    .multilineTextAlignment(.center)
                
                Text("\(champion.problemsSolved) solved")
                    .font(.custom("TTPhobosTrial-Regular", size: rank == 1 ? 10 : 9))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6)
            
            // Podium Base with Smooth Curves
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            rankColor.opacity(0.4),
                            rankColor.opacity(0.2)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(rankColor.opacity(0.6), lineWidth: 2)
                )
                .overlay(
                    Text("#\(rank)")
                        .font(.custom("TTPhobosTrial-Bold", size: rank == 1 ? 20 : 18))
                        .foregroundColor(rankColor)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - Warriors List
struct WarriorsList: View {
    let warriors: [LeaderboardHandle]
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("⚔️ Warriors Guild")
                    .font(.custom("TTPhobosTrial-Bold", size: 18))
                    .foregroundColor(colorThemeManager.current.text)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(warriors.enumerated()), id: \.element.id) { index, warrior in
                    WarriorCard(warrior: warrior, rank: index + 4) // +4 because we skip top 3
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

struct WarriorCard: View {
    let warrior: LeaderboardHandle
    let rank: Int
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @StateObject private var leaderboardManager = LeaderboardManager.shared
    
    private var rankBadge: String {
        switch rank {
        case 4...10: return "🛡️"
        case 11...20: return "⚔️"
        default: return "🗡️"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank and Badge
            VStack(spacing: 4) {
                Text(rankBadge)
                    .font(.system(size: 20))
                
                Text("#\(rank)")
                    .font(.custom("TTPhobosTrial-Bold", size: 12))
                    .foregroundColor(colorThemeManager.current.accent)
                    .multilineTextAlignment(.center)
            }
            .frame(minWidth: 40)
            
            // Avatar
            Circle()
                .fill(colorThemeManager.current.text.opacity(0.2))
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                        .font(.system(size: 16))
                }
            .frame(width: 42, height: 42)
            .shadow(color: colorThemeManager.current.accent.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Warrior Info - Flexible layout
            VStack(alignment: .leading, spacing: 8) {
                Text(warrior.handle)
                    .font(.custom("TTPhobosTrial-Bold", size: 16))
                    .foregroundColor(colorThemeManager.current.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Flexible stats layout
                HStack(spacing: 16) {
                    // Rating Stat
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.ratingColor(for: warrior.rating))
                        
                        Text("\(warrior.rating)")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 13))
                            .foregroundColor(Color.ratingColor(for: warrior.rating))
                            .lineLimit(1)
                    }
                    .layoutPriority(1)
                    
                    // Problems Solved Stat
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("\(warrior.problemsSolved)")
                            .font(.custom("TTPhobosTrial-DemiBold", size: 13))
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }
                    .layoutPriority(1)
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Actions - More compact
            Menu {
                Button("View Profile", action: {
                    // TODO: Navigate to profile
                })
                
                Button("Remove", role: .destructive, action: {
                    leaderboardManager.removeHandle(warrior)
                })
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(colorThemeManager.current.text.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorThemeManager.current.background.opacity(0.7))
                .stroke(colorThemeManager.current.accent.opacity(0.15), lineWidth: 1)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Empty State
struct EmptyHallOfFameView: View {
    @Binding var showingAddHandle: Bool
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🏛️")
                .font(.system(size: 80))
            
            VStack(spacing: 12) {
                Text("Hall of Fame Awaits")
                    .font(.custom("TTPhobosTrial-Bold", size: 24))
                    .foregroundColor(colorThemeManager.current.text)
                
                Text("Add fellow warriors to compete and track progress together")
                    .font(.custom("TTPhobosTrial-Regular", size: 16))
                    .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                showingAddHandle = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    
                    Text("Add First Warrior")
                        .font(.custom("TTPhobosTrial-Bold", size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorThemeManager.current.accent)
                )
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorThemeManager.current.tabBar.opacity(0.9))
                .shadow(color: colorThemeManager.current.accent.opacity(0.08), radius: 8, y: 2)
        )
    }
}

// MARK: - Add Handle Sheet
struct DungeonAddHandleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var leaderboardManager = LeaderboardManager.shared
    @EnvironmentObject var colorThemeManager: ColorThemeManager
    @State private var newHandle = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                colorThemeManager.current.background
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("⚔️")
                            .font(.system(size: 60))
                        
                        VStack(spacing: 8) {
                            Text("Recruit Warrior")
                                .font(.custom("TTPhobosTrial-Bold", size: 24))
                                .foregroundColor(colorThemeManager.current.text)
                            
                            Text("Add a fellow coder to your leaderboard")
                                .font(.custom("TTPhobosTrial-Regular", size: 16))
                                .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Input Section
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Codeforces Handle")
                                    .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                                    .foregroundColor(colorThemeManager.current.text)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(colorThemeManager.current.accent)
                                
                                TextField("Enter handle", text: $newHandle)
                                    .font(.custom("TTPhobosTrial-Regular", size: 16))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(colorThemeManager.current.text)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(colorThemeManager.current.tabBar.opacity(0.8))
                                    .stroke(colorThemeManager.current.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                
                                Text(errorMessage)
                                    .font(.custom("TTPhobosTrial-Regular", size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.red.opacity(0.1))
                                    .stroke(.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                            .foregroundColor(colorThemeManager.current.text.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(colorThemeManager.current.tabBar.opacity(0.5))
                            )
                            
                            Button(action: addHandle) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                    }
                                    
                                    Text(isLoading ? "Recruiting..." : "Add Warrior")
                                        .font(.custom("TTPhobosTrial-Bold", size: 16))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(newHandle.isEmpty || isLoading ? colorThemeManager.current.text.opacity(0.3) : colorThemeManager.current.accent)
                                )
                            }
                            .disabled(newHandle.isEmpty || isLoading)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 60)
            }
            .navigationTitle("Add Warrior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.custom("TTPhobosTrial-DemiBold", size: 16))
                }
            }
        }
    }
    
    private func addHandle() {
        guard !newHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                await leaderboardManager.addHandle(newHandle.trimmingCharacters(in: .whitespacesAndNewlines))
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to add warrior. Please check the handle and try again."
                }
            }
        }
    }
}

#Preview {
    DungeonLeaderboardView()
        .environmentObject(ColorThemeManager())
}
