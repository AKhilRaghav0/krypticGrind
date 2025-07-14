import SwiftUI

extension Color {
    static let cream = Color(red: 255/255, green: 242/255, blue: 224/255)
    static let lightLavender = Color(red: 192/255, green: 201/255, blue: 238/255)
    static let lavender = Color(red: 162/255, green: 170/255, blue: 219/255)
    static let mutedPurple = Color(red: 137/255, green: 138/255, blue: 196/255)
}

struct ColorTheme: Identifiable, Equatable {
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
}

class ColorThemeManager: ObservableObject {
    @Published var currentThemeIndex: Int = 0 {
        didSet { objectWillChange.send() }
    }
    var themes: [ColorTheme] = [
        // Palette 1 (Ocean) - Professional and calming
        ColorTheme(
            name: "Ocean",
            background: Color(hex: "#0F172A"), // Dark slate
            tabBar: Color(hex: "#1E293B"),     // Slate 800
            accent: Color(hex: "#3B82F6"),     // Blue 500
            text: Color(hex: "#F1F5F9"),       // Slate 100
            secondary: Color(hex: "#64748B"),  // Slate 500
            error: Color(hex: "#EF4444"),      // Red 500
            link: Color(hex: "#06B6D4")        // Cyan 500
        ),
        
        // Palette 2 (Sunset) - Warm and energetic
        ColorTheme(
            name: "Sunset",
            background: Color(hex: "#1A1A2E"), // Deep navy
            tabBar: Color(hex: "#16213E"),     // Dark blue
            accent: Color(hex: "#F59E0B"),     // Amber 500
            text: Color(hex: "#FEF3C7"),       // Amber 100
            secondary: Color(hex: "#92400E"),  // Amber 800
            error: Color(hex: "#DC2626"),      // Red 600
            link: Color(hex: "#F472B6")        // Pink 400
        ),
        
        // Palette 3 (Forest) - Nature-inspired focus
        ColorTheme(
            name: "Forest",
            background: Color(hex: "#0F1419"), // Very dark green
            tabBar: Color(hex: "#1F2937"),     // Gray 800
            accent: Color(hex: "#10B981"),     // Emerald 500
            text: Color(hex: "#ECFDF5"),       // Emerald 50
            secondary: Color(hex: "#6B7280"),  // Gray 500
            error: Color(hex: "#F87171"),      // Red 400
            link: Color(hex: "#34D399")        // Emerald 400
        ),
        
        // Palette 4 (Cosmic) - Modern purple theme
        ColorTheme(
            name: "Cosmic",
            background: Color(hex: "#0A0A0F"), // Deep space
            tabBar: Color(hex: "#16161A"),     // Card surface
            accent: Color(hex: "#7C3AED"),     // Violet 600
            text: Color(hex: "#F8FAFC"),       // Slate 50
            secondary: Color(hex: "#94A3B8"),  // Slate 400
            error: Color(hex: "#EF4565"),      // Pink red
            link: Color(hex: "#A78BFA")        // Violet 400
        ),
        
        // Palette 5 (Minimal) - Clean and minimalist
        ColorTheme(
            name: "Minimal",
            background: Color(hex: "#FAFAFA"), // Almost white
            tabBar: Color(hex: "#FFFFFF"),     // Pure white
            accent: Color(hex: "#1F2937"),     // Gray 800
            text: Color(hex: "#111827"),       // Gray 900
            secondary: Color(hex: "#6B7280"),  // Gray 500
            error: Color(hex: "#DC2626"),      // Red 600
            link: Color(hex: "#2563EB")        // Blue 600
        ),
        
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

    var current: ColorTheme { themes[currentThemeIndex % themes.count] }

    /// Advances to the next color theme in the list, cycling back to the first theme if at the end.
    func nextTheme() {
        currentThemeIndex = (currentThemeIndex + 1) % themes.count
    }
    
    /// Sets the current theme to the theme at the specified index if the index is valid.
    /// - Parameter index: The index of the theme to activate. Indices outside the valid range are ignored.
    func setTheme(index: Int) {
        guard index >= 0 && index < themes.count else { return }
        currentThemeIndex = index
    }
    
    /// Returns the color theme at the specified index if it exists.
    /// - Parameter index: The index of the desired theme.
    /// - Returns: The `ColorTheme` at the given index, or `nil` if the index is out of bounds.
    func getTheme(at index: Int) -> ColorTheme? {
        guard index >= 0 && index < themes.count else { return nil }
        return themes[index]
    }
}