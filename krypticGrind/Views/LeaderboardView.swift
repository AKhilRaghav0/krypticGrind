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
                        .padding()
                    
                    if leaderboardManager.handles.isEmpty {
                        EmptyLeaderboardView()
                    } else {
                        LeaderboardList(handles: filteredHandles)
                    }
                }
            }
            .background(themeManager.colors.background)
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddHandle = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(themeManager.colors.accent)
                    }
                }
            }
        }
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
            LazyVStack(spacing: 12) {
                ForEach(Array(sortedHandles.enumerated()), id: \.element.id) { index, handle in
                    LeaderboardCard(handle: handle, rank: index + 1)
                }
            }
            .padding()
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
        default: return .blue
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
        VStack(alignment: .leading, spacing: 12) {
            // Header with rank and handle
            HStack {
                HStack(spacing: 8) {
                    Text(rankIcon)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(handle.handle)
                            .font(.headline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        if let firstName = handle.firstName {
                            Text(firstName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                }
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatItem(title: "Rating", value: "\(handle.rating)", icon: "chart.line.uptrend.xyaxis", color: .blue)
                StatItem(title: "Problems", value: "\(handle.problemsSolved)", icon: "checkmark.circle", color: .green)
                StatItem(title: "Contests", value: "\(handle.contestsParticipated)", icon: "trophy", color: .orange)
            }
            
            // Rating change
            if handle.ratingChange != 0 {
                HStack {
                    Image(systemName: handle.ratingChange > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(handle.ratingChange > 0 ? .green : .red)
                    
                    Text("\(handle.ratingChange > 0 ? "+" : "")\(handle.ratingChange)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(handle.ratingChange > 0 ? .green : .red)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rankColor.opacity(0.3), lineWidth: rank <= 3 ? 2 : 0)
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct EmptyLeaderboardView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "trophy")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange.gradient)
                
                VStack(spacing: 8) {
                    Text("No Handles Added")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Add Codeforces handles to compare your progress with friends and other coders.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Button("Add First Handle") {
                // This will be handled by the sheet
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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