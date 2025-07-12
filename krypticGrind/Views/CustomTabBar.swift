import SwiftUI

enum MainTab: Int, CaseIterable {
    case rating, submissions, home, contests, practice
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.cream.opacity(0.95))
                .shadow(color: Color.mutedPurple.opacity(0.18), radius: 16, y: 4)
                .frame(height: 70)
                .padding(.horizontal, 16)

            HStack(spacing: 0) {
                tabButton(.rating, icon: "chart.line.uptrend.xyaxis", label: "Rating")
                tabButton(.submissions, icon: "doc.text", label: "Submissions")
                Spacer(minLength: 0)
                tabButton(.contests, icon: "trophy", label: "Contests")
                tabButton(.practice, icon: "target", label: "Practice")
            }
            .padding(.horizontal, 32)

            // Center Home Button (popped up)
            HStack {
                Spacer()
                Button(action: { selectedTab = .home }) {
                    ZStack {
                        Circle()
                            .fill(Color.lavender)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.mutedPurple.opacity(0.25), radius: 12, y: 4)
                        // Home Icon (thin weight)
                        Image(systemName: "house.fill")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundColor(.cream)
                    }
                }
                .offset(y: -32)
                Spacer()
            }
        }
        .frame(height: 90)
    }

    @ViewBuilder
    func tabButton(_ tab: MainTab, icon: String, label: String) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .thin))
                    .foregroundColor(selectedTab == tab ? .lavender : .mutedPurple.opacity(0.7))
                Text(label)
                    .font(.ttphobosCaption)
                    .foregroundColor(selectedTab == tab ? .lavender : .mutedPurple.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
    }
} 