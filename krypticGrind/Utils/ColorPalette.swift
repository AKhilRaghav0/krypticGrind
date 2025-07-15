import SwiftUI

extension Color {
    static let cream = Color(red: 255/255, green: 242/255, blue: 224/255)
    static let lightLavender = Color(red: 192/255, green: 201/255, blue: 238/255)
    static let lavender = Color(red: 162/255, green: 170/255, blue: 219/255)
    static let mutedPurple = Color(red: 137/255, green: 138/255, blue: 196/255)
}

struct ColorTheme: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let background: Color
    let tabBar: Color
    let accent: Color
    let text: Color
    let secondary: Color
    // Optionals for advanced roles
    let error: Color?
    let link: Color?
    
    // Additional computed properties for better naming
    var textPrimary: Color { text }
    var textSecondary: Color { secondary }
    var surface: Color { tabBar }
    var divider: Color { secondary.opacity(0.3) }
    var success: Color { error ?? Color.green }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    
    var colors: ColorSchemeColors {
        ColorSchemeColors(
            background: background,
            tabBar: tabBar,
            accent: accent,
            text: text,
            secondary: secondary
        )
    }
}

extension ColorTheme: CaseIterable {
    static var allCases: [ColorTheme] {
        return [
            // Palette 1 (Ocean) - Professional and calming
            ColorTheme(
                name: "Ocean",
                background: Color(hex: "#0F172A"),
                tabBar: Color(hex: "#1E293B"),
                accent: Color(hex: "#3B82F6"),
                text: Color(hex: "#F1F5F9"),
                secondary: Color(hex: "#64748B"),
                error: Color(hex: "#EF4444"),
                link: Color(hex: "#06B6D4")
            ),
            
            // Palette 2 (Sunset) - Warm and energetic
            ColorTheme(
                name: "Sunset",
                background: Color(hex: "#1A1A2E"),
                tabBar: Color(hex: "#16213E"),
                accent: Color(hex: "#F59E0B"),
                text: Color(hex: "#FEF3C7"),
                secondary: Color(hex: "#92400E"),
                error: Color(hex: "#DC2626"),
                link: Color(hex: "#F472B6")
            ),
            
            // Palette 3 (Forest) - Nature-inspired focus
            ColorTheme(
                name: "Forest",
                background: Color(hex: "#0F1419"),
                tabBar: Color(hex: "#1F2937"),
                accent: Color(hex: "#10B981"),
                text: Color(hex: "#ECFDF5"),
                secondary: Color(hex: "#6B7280"),
                error: Color(hex: "#F87171"),
                link: Color(hex: "#34D399")
            ),
            
            // Palette 4 (Cosmic) - Modern purple theme
            ColorTheme(
                name: "Cosmic",
                background: Color(hex: "#0A0A0F"),
                tabBar: Color(hex: "#16161A"),
                accent: Color(hex: "#7C3AED"),
                text: Color(hex: "#F8FAFC"),
                secondary: Color(hex: "#94A3B8"),
                error: Color(hex: "#EF4565"),
                link: Color(hex: "#A78BFA")
            ),
            
            // Palette 5 (Minimal) - Clean and minimalist
            ColorTheme(
                name: "Minimal",
                background: Color(hex: "#FAFAFA"),
                tabBar: Color(hex: "#FFFFFF"),
                accent: Color(hex: "#1F2937"),
                text: Color(hex: "#111827"),
                secondary: Color(hex: "#6B7280"),
                error: Color(hex: "#DC2626"),
                link: Color(hex: "#2563EB")
            )
        ]
    }
}

struct ColorSchemeColors {
    let background: Color
    let tabBar: Color
    let accent: Color
    let text: Color
    let secondary: Color
}

class ColorThemeManager: ObservableObject {
    @Published var currentThemeIndex: Int = 0 {
        didSet { objectWillChange.send() }
    }
    
    @Published var selectedTheme: ColorTheme = ColorTheme.allCases.first ?? ColorTheme(
        name: "Default",
        background: .black,
        tabBar: .gray,
        accent: .blue,
        text: .white,
        secondary: .gray,
        error: .red,
        link: .blue
    ) {
        didSet { 
            if let index = themes.firstIndex(where: { $0.name == selectedTheme.name }) {
                currentThemeIndex = index
            }
        }
    }
    
    var themes: [ColorTheme] {
        return ColorTheme.allCases + legacyThemes
    }
    
    private var legacyThemes: [ColorTheme] = [
        // Legacy themes (keeping for existing users)
        ColorTheme(
            name: "Lavender",
            background: Color(red: 192/255, green: 201/255, blue: 238/255),
            tabBar: Color(red: 255/255, green: 242/255, blue: 224/255),
            accent: Color(red: 162/255, green: 170/255, blue: 219/255),
            text: Color(red: 137/255, green: 138/255, blue: 196/255),
            secondary: Color(red: 255/255, green: 242/255, blue: 224/255),
            error: nil, link: nil
        ),
        
        ColorTheme(
            name: "Cyberpunk",
            background: Color(hex: "#0A0A0F"),
            tabBar: Color(hex: "#16161A"),
            accent: Color(hex: "#7F5AF0"),
            text: Color(hex: "#F8F8F2"),
            secondary: Color(hex: "#94A1B2"),
            error: Color(hex: "#EF4565"),
            link: Color(hex: "#00BFFF")
        )
    ]

    init() {
        self.selectedTheme = themes[0] // Initialize with first theme
    }

    var current: ColorTheme { themes[currentThemeIndex % themes.count] }

    func nextTheme() {
        currentThemeIndex = (currentThemeIndex + 1) % themes.count
    }
    
    func setTheme(index: Int) {
        guard index >= 0 && index < themes.count else { return }
        currentThemeIndex = index
    }
    
    func getTheme(at index: Int) -> ColorTheme? {
        guard index >= 0 && index < themes.count else { return nil }
        return themes[index]
    }
}