import SwiftUI

struct LeaderboardView: View {
    @StateObject private var themeManager = ThemeManager.shared
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(searchText: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    if leaderboardManager.handles.isEmpty {
                        EmptyLeaderboardView(showingAddHandle: $showingAddHandle)
                    } else {
                        LeaderboardList(handles: filteredHandles)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(themeManager.colors.accent)
        .sheet(isPresented: $showingAddHandle) {
            AddHandleSheet()
        }
        .task {
            await leaderboardManager.refreshAllHandles()
        }
    }
}

struct LeaderboardList: View {
    let handles: [LeaderboardHandle]
    @StateObject private var themeManager = ThemeManager.shared
    
    var sortedHandles: [LeaderboardHandle] {
        handles.sorted { handle1, handle2 in
            // Sort by rating (descending), then by problems solved (descending)
            if handle1.rating != handle2.rating {
                return handle1.rating > handle2.rating
            }
            return handle1.problemsSolved > handle2.problemsSolved
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(sortedHandles.enumerated()), id: \.element.id) { index, handle in
                    LeaderboardCard(handle: handle, rank: index + 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
}

struct LeaderboardCard: View {
    let handle: LeaderboardHandle
    let rank: Int
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var leaderboardManager = LeaderboardManager.shared
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return themeManager.colors.accent
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with rank and handle
            HStack {
                HStack(spacing: 12) {
                    Text(rankIcon)
                        .font(.system(size: 24, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(handle.handle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(themeManager.colors.textPrimary)
                        
                        if let firstName = handle.firstName {
                            Text(firstName)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(themeManager.colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("Refresh") {
                        Task {
                            await leaderboardManager.refreshHandle(handle)
                        }
                    }
                    
                    Button("Remove", role: .destructive) {
                        leaderboardManager.removeHandle(handle)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(themeManager.colors.textSecondary)
                        .font(.system(size: 18))
                }
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatItem(title: "Rating", value: "\(handle.rating)", icon: "chart.line.uptrend.xyaxis", color: Color.ratingColor(for: handle.rating))
                StatItem(title: "Problems", value: "\(handle.problemsSolved)", icon: "checkmark.circle.fill", color: .green)
                StatItem(title: "Contests", value: "\(handle.contestsParticipated)", icon: "trophy.fill", color: .orange)
            }
            
            // Rating change
            if handle.ratingChange != 0 {
                HStack(spacing: 8) {
                    Image(systemName: handle.ratingChange > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(handle.ratingChange > 0 ? .green : .red)
                    
                    Text("\(handle.ratingChange > 0 ? "+" : "")\(handle.ratingChange)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(handle.ratingChange > 0 ? .green : .red)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(rankColor.opacity(0.3), lineWidth: rank <= 3 ? 2 : 0)
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(themeManager.colors.textPrimary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(themeManager.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

struct EmptyLeaderboardView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Binding var showingAddHandle: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "trophy")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(themeManager.colors.textSecondary)
            
            VStack(spacing: 8) {
                Text("No Handles Added")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(themeManager.colors.textPrimary)
                
                Text("Add Codeforces handles to start tracking your leaderboard")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(themeManager.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddHandle = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Add Handle")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeManager.colors.accent)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(themeManager.colors.textSecondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search handles...", text: $searchText)
                .foregroundStyle(themeManager.colors.textPrimary)
                .font(.system(size: 16, weight: .regular))
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeManager.colors.textSecondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

struct AddHandleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var leaderboardManager = LeaderboardManager.shared
    @State private var handleText = ""
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Handle")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                        
                        Text("Enter a Codeforces handle to add to your leaderboard")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Handle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("e.g., tourist", text: $handleText)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Verifying handle...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Handle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addHandle()
                    }
                    .foregroundStyle(themeManager.colors.accent)
                    .disabled(handleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
    }
    
    private func addHandle() {
        let handle = handleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !handle.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        Task {
            let result = await leaderboardManager.addHandle(handle)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success:
                    dismiss()
                case .failure(let errorType):
                    error = errorType.localizedDescription
                }
            }
        }
    }
} 