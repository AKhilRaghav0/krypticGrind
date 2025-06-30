//
//  Extensions.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI
import Foundation

// MARK: - Color Extensions
extension Color {
    // MARK: - Current KrypticGrind Colors
    // KrypticGrind brand colors
    static let krypticBlue = Color(red: 0.0, green: 0.7, blue: 1.0)
    static let krypticPurple = Color(red: 0.6, green: 0.3, blue: 1.0)
    static let krypticDark = Color(red: 0.1, green: 0.1, blue: 0.12)
    static let krypticGray = Color(red: 0.2, green: 0.2, blue: 0.24)
    
    // MARK: - Future Modern Color Schemes
    // TODO: Choose and implement one of these beautiful color schemes
    
    /*
    🎨 OPTION 1: "Midnight Pro" - Ultra Modern Dark
    | Role                | Light Mode     | Dark Mode      | Usage                       |
    | ------------------- | -------------- | -------------- | --------------------------- |
    | **Background**      | `#FAFAFA`      | `#0A0A0B`      | Primary view backgrounds    |
    | **Surface Card**    | `#FFFFFF`      | `#1A1A1D`      | Cards, sheets, modals       |
    | **Text Primary**    | `#1A1A1D`      | `#F5F5F7`      | Main labels, body copy      |
    | **Text Secondary**  | `#6B6B70`      | `#98989F`      | Subtitles, footers          |
    | **Accent**          | `#007AFF`      | `#0A84FF`      | Primary actions, buttons    |
    | **Highlight**       | `#5856D6`      | `#5E5CE6`      | Charts, rating lines        |
    | **Success**         | `#34C759`      | `#30D158`      | AC submissions, achievements|
    | **Warning**         | `#FF9500`      | `#FF9F0A`      | Warnings, time limits       |
    | **Error**           | `#FF3B30`      | `#FF453A`      | Errors, failed submissions  |
    | **Divider**         | `#E5E5EA`      | `#38383A`      | Separators, borders         |
    
    🎨 OPTION 2: "Gradient Flow" - Vibrant & Modern
    | Role                | Light Mode     | Dark Mode      | Usage                       |
    | ------------------- | -------------- | -------------- | --------------------------- |
    | **Background**      | `#F8F9FA`      | `#0D1117`      | Primary view backgrounds    |
    | **Surface Card**    | `#FFFFFF`      | `#161B22`      | Cards, sheets, modals       |
    | **Text Primary**    | `#24292F`      | `#F0F6FC`      | Main labels, body copy      |
    | **Text Secondary**  | `#656D76`      | `#8B949E`      | Subtitles, footers          |
    | **Accent**          | `#0969DA`      | `#58A6FF`      | Primary actions, buttons    |
    | **Highlight**       | `#8B5CF6`      | `#A78BFA`      | Charts, rating lines        |
    | **Success**         | `#1A7F37`      | `#3FB950`      | AC submissions, achievements|
    | **Warning**         | `#D1242F`      | `#F85149`      | Warnings, time limits       |
    | **Error**           | `#CF222E`      | `#FF7B72`      | Errors, failed submissions  |
    | **Divider**         | `#D1D9E0`      | `#30363D`      | Separators, borders         |
    
    🎨 OPTION 3: "Ocean Depth" - Cool & Sophisticated
    | Role                | Light Mode     | Dark Mode      | Usage                       |
    | ------------------- | -------------- | -------------- | --------------------------- |
    | **Background**      | `#F7F9FC`      | `#0B1426`      | Primary view backgrounds    |
    | **Surface Card**    | `#FFFFFF`      | `#1A2332`      | Cards, sheets, modals       |
    | **Text Primary**    | `#1E293B`      | `#F1F5F9`      | Main labels, body copy      |
    | **Text Secondary**  | `#64748B`      | `#94A3B8`      | Subtitles, footers          |
    | **Accent**          | `#0EA5E9`      | `#38BDF8`      | Primary actions, buttons    |
    | **Highlight**       | `#8B5CF6`      | `#C084FC`      | Charts, rating lines        |
    | **Success**         | `#059669`      | `#10B981`      | AC submissions, achievements|
    | **Warning**         | `#D97706`      | `#F59E0B`      | Warnings, time limits       |
    | **Error**           | `#DC2626`      | `#EF4444`      | Errors, failed submissions  |
    | **Divider**         | `#E2E8F0`      | `#334155`      | Separators, borders         |
    
    🎨 OPTION 4: "Neon Nights" - Gaming Inspired
    | Role                | Light Mode     | Dark Mode      | Usage                       |
    | ------------------- | -------------- | -------------- | --------------------------- |
    | **Background**      | `#FAFAFA`      | `#0A0A0A`      | Primary view backgrounds    |
    | **Surface Card**    | `#FFFFFF`      | `#1A1A1A`      | Cards, sheets, modals       |
    | **Text Primary**    | `#1A1A1A`      | `#FFFFFF`      | Main labels, body copy      |
    | **Text Secondary**  | `#6B6B6B`      | `#A3A3A3`      | Subtitles, footers          |
    | **Accent**          | `#00D4FF`      | `#00E5FF`      | Primary actions, buttons    |
    | **Highlight**       | `#9D4EDD`      | `#C77DFF`      | Charts, rating lines        |
    | **Success**         | `#39FF14`      | `#39FF14`      | AC submissions, achievements|
    | **Warning**         | `#FFD60A`      | `#FFD60A`      | Warnings, time limits       |
    | **Error**           | `#FF073A`      | `#FF073A`      | Errors, failed submissions  |
    | **Divider**         | `#E0E0E0`      | `#333333`      | Separators, borders         |
    
    🎨 OPTION 5: "Pastel Dreams" - Soft & Beautiful
    | Role                | Light Mode     | Dark Mode      | Usage                       |
    | ------------------- | -------------- | -------------- | --------------------------- |
    | **Background**      | `#F8F8FF`      | `#1C1B29`      | Primary view backgrounds    |
    | **Surface Card**    | `#FFFFFF`      | `#2A2A3E`      | Cards, sheets, modals       |
    | **Text Primary**    | `#2D2A4A`      | `#F0F0F5`      | Main labels, body copy      |
    | **Text Secondary**  | `#6C6B93`      | `#B5B3D3`      | Subtitles, footers          |
    | **Accent**          | `#6366F1`      | `#818CF8`      | Primary actions, buttons    |
    | **Highlight**       | `#EC4899`      | `#F472B6`      | Charts, rating lines        |
    | **Success**         | `#10B981`      | `#34D399`      | AC submissions, achievements|
    | **Warning**         | `#F59E0B`      | `#FBBF24`      | Warnings, time limits       |
    | **Error**           | `#EF4444`      | `#F87171`      | Errors, failed submissions  |
    | **Divider**         | `#E5E7EB`      | `#4B5563`      | Separators, borders         |
    */
    
    // Rating colors
    static let cfGray = Color.gray
    static let cfGreen = Color.green
    static let cfCyan = Color.cyan
    static let cfBlue = Color.blue
    static let cfPurple = Color.purple
    static let cfOrange = Color.orange
    static let cfRed = Color.red
    
    // Verdict colors
    static let acGreen = Color.green
    static let waRed = Color.red
    static let tleOrange = Color.orange
    static let mleOrange = Color.orange
    static let rtePurple = Color.purple
    static let ceGray = Color.gray
    
    static func ratingColor(for rating: Int) -> Color {
        switch rating {
        case 1200..<1400: return .cfGreen
        case 1400..<1600: return .cfCyan
        case 1600..<1900: return .cfBlue
        case 1900..<2100: return .cfPurple
        case 2100..<2300: return .cfOrange
        case 2300..<2400: return .cfRed
        case 2400...: return .cfRed
        default: return .cfGray
        }
    }
    
    static func verdictColor(for verdict: String) -> Color {
        switch verdict {
        case "OK": return .acGreen
        case "WRONG_ANSWER": return .waRed
        case "TIME_LIMIT_EXCEEDED": return .tleOrange
        case "MEMORY_LIMIT_EXCEEDED": return .mleOrange
        case "RUNTIME_ERROR": return .rtePurple
        case "COMPILATION_ERROR": return .ceGray
        default: return .blue
        }
    }
    
    // MARK: - Hex Color Support
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extensions
extension Date {
    func timeAgo() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)
        
        if timeInterval < 60 {
            return "just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if timeInterval < 2592000 {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: self)
        }
    }
    
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    func capitalized() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    var typeDisplayText: String {
        switch self {
        case "CF": return "Codeforces"
        case "IOI": return "IOI"
        case "ICPC": return "ICPC"
        default: return self.capitalized
        }
    }
}

// MARK: - Int Extensions
extension Int {
    var durationString: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Number Extensions
extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - View Extensions
extension View {
    func cardBackground() -> some View {
        self
            .background(Color.krypticGray)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    func glowEffect(color: Color = .krypticBlue, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius)
    }
    
    func pulseAnimation() -> some View {
        self
            .scaleEffect(1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    private enum Keys {
        static let savedHandle = "saved_handle"
        static let dailyGoal = "daily_goal"
        static let goalProgress = "goal_progress"
        static let lastGoalDate = "last_goal_date"
        static let isDarkMode = "is_dark_mode"
        static let showNotifications = "show_notifications"
        static let selectedTheme = "selected_theme"
    }
    
    var savedHandle: String? {
        get { string(forKey: Keys.savedHandle) }
        set { set(newValue, forKey: Keys.savedHandle) }
    }
    
    var dailyGoal: Int {
        get { 
            let goal = integer(forKey: Keys.dailyGoal)
            return goal == 0 ? 3 : goal // Default to 3 problems per day
        }
        set { set(newValue, forKey: Keys.dailyGoal) }
    }
    
    var goalProgress: Int {
        get { integer(forKey: Keys.goalProgress) }
        set { set(newValue, forKey: Keys.goalProgress) }
    }
    
    var lastGoalDate: Date? {
        get { object(forKey: Keys.lastGoalDate) as? Date }
        set { set(newValue, forKey: Keys.lastGoalDate) }
    }
    
    var isDarkMode: Bool {
        get { 
            if object(forKey: Keys.isDarkMode) == nil {
                return true // Default to dark mode
            }
            return bool(forKey: Keys.isDarkMode)
        }
        set { set(newValue, forKey: Keys.isDarkMode) }
    }
    
    var showNotifications: Bool {
        get { 
            if object(forKey: Keys.showNotifications) == nil {
                return true // Default to showing notifications
            }
            return bool(forKey: Keys.showNotifications)
        }
        set { set(newValue, forKey: Keys.showNotifications) }
    }
    
    var selectedTheme: AppTheme {
        get {
            let themeString = string(forKey: Keys.selectedTheme) ?? AppTheme.classic.rawValue
            return AppTheme(rawValue: themeString) ?? .classic
        }
        set { set(newValue.rawValue, forKey: Keys.selectedTheme) }
    }
}

// MARK: - Array Extensions
extension Array where Element == CFSubmission {
    func todaysSubmissions() -> [CFSubmission] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return self.filter { submission in
            let submissionDate = submission.submissionDate
            return submissionDate >= today && submissionDate < tomorrow
        }
    }
    
    func acceptedSubmissions() -> [CFSubmission] {
        return self.filter { $0.isAccepted }
    }
}

// MARK: - Theme System
enum AppTheme: String, CaseIterable, Identifiable {
    case classic = "classic"
    case midnightPro = "midnight_pro"
    case gradientFlow = "gradient_flow"
    case oceanDepth = "ocean_depth"
    case neonNights = "neon_nights"
    case pastelDreams = "pastel_dreams"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic: return "KrypticGrind Classic"
        case .midnightPro: return "Midnight Pro"
        case .gradientFlow: return "Gradient Flow"
        case .oceanDepth: return "Ocean Depth"
        case .neonNights: return "Neon Nights"
        case .pastelDreams: return "Pastel Dreams"
        }
    }
    
    var description: String {
        switch self {
        case .classic: return "Original KrypticGrind colors"
        case .midnightPro: return "Ultra modern dark theme"
        case .gradientFlow: return "Vibrant & modern design"
        case .oceanDepth: return "Cool & sophisticated"
        case .neonNights: return "Gaming inspired colors"
        case .pastelDreams: return "Soft & beautiful palette"
        }
    }
    
    var colors: ThemeColors {
        // Use static value instead of accessing actor-isolated property
        let colorScheme = UserDefaults.standard.object(forKey: "is_dark_mode") as? Bool
        let isDarkMode: Bool
        
        if let colorScheme = colorScheme {
            isDarkMode = colorScheme
        } else {
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        return isDarkMode ? darkColors : lightColors
    }
    
    var lightColors: ThemeColors {
        switch self {
        case .classic:
            return ThemeColors(
                background: Color(hex: "#F8F9FA"),
                surface: Color(hex: "#FFFFFF"),
                textPrimary: Color(hex: "#1A1A1D"),
                textSecondary: Color(hex: "#6B6B70"),
                accent: Color.krypticBlue,
                highlight: Color.krypticPurple,
                success: Color.green,
                warning: Color.orange,
                error: Color.red,
                divider: Color(hex: "#E5E5EA")
            )
        case .midnightPro:
            return ThemeColors(
                background: Color(hex: "#FAFAFA"),
                surface: Color(hex: "#FFFFFF"),
                textPrimary: Color(hex: "#1A1A1D"),
                textSecondary: Color(hex: "#6B6B70"),
                accent: Color(hex: "#007AFF"),
                highlight: Color(hex: "#5856D6"),
                success: Color(hex: "#34C759"),
                warning: Color(hex: "#FF9500"),
                error: Color(hex: "#FF3B30"),
                divider: Color(hex: "#E5E5EA")
            )
        case .gradientFlow:
            return ThemeColors(
                background: Color(hex: "#F8F9FA"),
                surface: Color(hex: "#FFFFFF"),
                textPrimary: Color(hex: "#24292F"),
                textSecondary: Color(hex: "#656D76"),
                accent: Color(hex: "#0969DA"),
                highlight: Color(hex: "#8B5CF6"),
                success: Color(hex: "#1A7F37"),
                warning: Color(hex: "#D1242F"),
                error: Color(hex: "#CF222E"),
                divider: Color(hex: "#D1D9E0")
            )
        case .oceanDepth:
            return ThemeColors(
                background: Color(hex: "#F7F9FC"),
                surface: Color(hex: "#FFFFFF"),
                textPrimary: Color(hex: "#1E293B"),
                textSecondary: Color(hex: "#64748B"),
                accent: Color(hex: "#0EA5E9"),
                highlight: Color(hex: "#8B5CF6"),
                success: Color(hex: "#059669"),
                warning: Color(hex: "#D97706"),
                error: Color(hex: "#DC2626"),
                divider: Color(hex: "#E2E8F0")
            )
        case .neonNights:
            return ThemeColors(
                background: Color(hex: "#FAFAFA"),
                surface: Color(hex: "#FFFFFF"),
                textPrimary: Color(hex: "#1A1A1A"),
                textSecondary: Color(hex: "#6B6B6B"),
                accent: Color(hex: "#00D4FF"),
                highlight: Color(hex: "#9D4EDD"),
                success: Color(hex: "#39FF14"),
                warning: Color(hex: "#FFD60A"),
                error: Color(hex: "#FF073A"),
                divider: Color(hex: "#E0E0E0")
            )
        case .pastelDreams:
            return ThemeColors(
                background: Color(hex: "#F8F8FF"),
                surface: Color(hex: "#FFFFFF"),
                textPrimary: Color(hex: "#2D2A4A"),
                textSecondary: Color(hex: "#6C6B93"),
                accent: Color(hex: "#6366F1"),
                highlight: Color(hex: "#EC4899"),
                success: Color(hex: "#10B981"),
                warning: Color(hex: "#F59E0B"),
                error: Color(hex: "#EF4444"),
                divider: Color(hex: "#E5E7EB")
            )
        }
    }
    
    var darkColors: ThemeColors {
        switch self {
        case .classic:
            return ThemeColors(
                background: Color.krypticDark,
                surface: Color.krypticGray,
                textPrimary: Color.white,
                textSecondary: Color.gray,
                accent: Color.krypticBlue,
                highlight: Color.krypticPurple,
                success: Color.green,
                warning: Color.orange,
                error: Color.red,
                divider: Color.gray.opacity(0.3)
            )
        case .midnightPro:
            return ThemeColors(
                background: Color(hex: "#0A0A0B"),
                surface: Color(hex: "#1A1A1D"),
                textPrimary: Color(hex: "#F5F5F7"),
                textSecondary: Color(hex: "#98989F"),
                accent: Color(hex: "#0A84FF"),
                highlight: Color(hex: "#5E5CE6"),
                success: Color(hex: "#30D158"),
                warning: Color(hex: "#FF9F0A"),
                error: Color(hex: "#FF453A"),
                divider: Color(hex: "#38383A")
            )
        case .gradientFlow:
            return ThemeColors(
                background: Color(hex: "#0D1117"),
                surface: Color(hex: "#161B22"),
                textPrimary: Color(hex: "#F0F6FC"),
                textSecondary: Color(hex: "#8B949E"),
                accent: Color(hex: "#58A6FF"),
                highlight: Color(hex: "#A78BFA"),
                success: Color(hex: "#3FB950"),
                warning: Color(hex: "#F85149"),
                error: Color(hex: "#FF7B72"),
                divider: Color(hex: "#30363D")
            )
        case .oceanDepth:
            return ThemeColors(
                background: Color(hex: "#0B1426"),
                surface: Color(hex: "#1A2332"),
                textPrimary: Color(hex: "#F1F5F9"),
                textSecondary: Color(hex: "#94A3B8"),
                accent: Color(hex: "#38BDF8"),
                highlight: Color(hex: "#C084FC"),
                success: Color(hex: "#10B981"),
                warning: Color(hex: "#F59E0B"),
                error: Color(hex: "#EF4444"),
                divider: Color(hex: "#334155")
            )
        case .neonNights:
            return ThemeColors(
                background: Color(hex: "#0A0A0A"),
                surface: Color(hex: "#1A1A1A"),
                textPrimary: Color(hex: "#FFFFFF"),
                textSecondary: Color(hex: "#A3A3A3"),
                accent: Color(hex: "#00E5FF"),
                highlight: Color(hex: "#C77DFF"),
                success: Color(hex: "#39FF14"),
                warning: Color(hex: "#FFD60A"),
                error: Color(hex: "#FF073A"),
                divider: Color(hex: "#333333")
            )
        case .pastelDreams:
            return ThemeColors(
                background: Color(hex: "#1C1B29"),
                surface: Color(hex: "#2A2A3E"),
                textPrimary: Color(hex: "#F0F0F5"),
                textSecondary: Color(hex: "#B5B3D3"),
                accent: Color(hex: "#818CF8"),
                highlight: Color(hex: "#F472B6"),
                success: Color(hex: "#34D399"),
                warning: Color(hex: "#FBBF24"),
                error: Color(hex: "#F87171"),
                divider: Color(hex: "#4B5563")
            )
        }
    }
}

struct ThemeColors {
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let highlight: Color
    let success: Color
    let warning: Color
    let error: Color
    let divider: Color
}

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selected_theme")
        }
    }
    
    @Published var colorScheme: ColorScheme? {
        didSet {
            if let scheme = colorScheme {
                UserDefaults.standard.set(scheme == .dark, forKey: "is_dark_mode")
            } else {
                UserDefaults.standard.removeObject(forKey: "is_dark_mode")
            }
            updateAppearance()
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selected_theme") ?? AppTheme.classic.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .classic
        
        if UserDefaults.standard.object(forKey: "is_dark_mode") != nil {
            self.colorScheme = UserDefaults.standard.bool(forKey: "is_dark_mode") ? .dark : .light
        } else {
            self.colorScheme = nil // System default
        }
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch colorScheme {
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .none:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    nonisolated var colors: ThemeColors {
        let userDefaults = UserDefaults.standard
        let isDark: Bool
        
        if userDefaults.object(forKey: "is_dark_mode") != nil {
            isDark = userDefaults.bool(forKey: "is_dark_mode")
        } else {
            isDark = UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        return isDark ? currentTheme.darkColors : currentTheme.lightColors
    }
}
