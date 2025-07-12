import SwiftUI

enum MainTab: Int, CaseIterable {
    case rating, submissions, home, contests, practice
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    @EnvironmentObject var colorThemeManager: ColorThemeManager

    var body: some View {
        let theme = colorThemeManager.current
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(theme.tabBar.opacity(0.95))
                .shadow(color: theme.accent.opacity(0.18), radius: 16, y: 4)
                .frame(height: 70)
                .padding(.horizontal, 16)
                .animation(.easeInOut, value: theme)

            HStack(spacing: 0) {
                tabButton(.rating, icon: "chart.line.uptrend.xyaxis", label: "Rating", theme: theme)
                tabButton(.submissions, icon: "doc.text", label: "Submissions", theme: theme)
                Spacer(minLength: 0)
                tabButton(.contests, icon: "trophy", label: "Contests", theme: theme)
                tabButton(.practice, icon: "target", label: "Practice", theme: theme)
            }
            .padding(.horizontal, 32)

            // Center Home Button (popped up)
            HStack {
                Spacer()
                Button(action: { selectedTab = .home }) {
                    ZStack {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 64, height: 64)
                            .shadow(color: theme.accent.opacity(0.25), radius: 12, y: 4)
                        // Home Icon (thin weight)
                        Image(systemName: "house.fill")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundColor(theme.tabBar)
                    }
                }
                .offset(y: -32)
                Spacer()
            }
        }
        .frame(height: 90)
        .animation(.easeInOut, value: theme)
    }

    @ViewBuilder
    func tabButton(_ tab: MainTab, icon: String, label: String, theme: ColorTheme) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .thin))
                    .foregroundColor(selectedTab == tab ? theme.accent : theme.text.opacity(0.7))
                Text(label)
                    .font(.ttphobosCaption)
                    .foregroundColor(selectedTab == tab ? theme.accent : theme.text.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
    }
} 