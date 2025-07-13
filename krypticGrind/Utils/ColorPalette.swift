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
        // Palette 1 (Lavender)
        ColorTheme(
            name: "Lavender",
            background: Color(red: 192/255, green: 201/255, blue: 238/255), // #C0C9EE
            tabBar: Color(red: 255/255, green: 242/255, blue: 224/255),     // #FFF2E0
            accent: Color(red: 162/255, green: 170/255, blue: 219/255),     // #A2AADB
            text: Color(red: 137/255, green: 138/255, blue: 196/255),       // #898AC4
            secondary: Color(red: 255/255, green: 242/255, blue: 224/255),  // #FFF2E0
            error: nil, link: nil
        ),
        // Palette 2 (Blue/Beige)
        ColorTheme(
            name: "BlueBeige",
            background: Color(red: 69/255, green: 104/255, blue: 130/255),   // #456882
            tabBar: Color(red: 249/255, green: 243/255, blue: 239/255),     // #F9F3EF
            accent: Color(red: 27/255, green: 60/255, blue: 83/255),        // #1B3C53
            text: Color(red: 27/255, green: 60/255, blue: 83/255),          // #1B3C53
            secondary: Color(red: 210/255, green: 193/255, blue: 182/255),  // #D2C1B6
            error: nil, link: nil
        ),
        // Palette 3 (Teal/Purple)
        ColorTheme(
            name: "TealPurple",
            background: Color(red: 15/255, green: 130/255, blue: 140/255),   // #0F828C
            tabBar: Color(red: 120/255, green: 185/255, blue: 181/255),     // #78B9B5
            accent: Color(red: 6/255, green: 80/255, blue: 132/255),        // #065084
            text: Color(red: 50/255, green: 10/255, blue: 107/255),         // #320A6B
            secondary: Color(red: 6/255, green: 80/255, blue: 132/255),     // #065084
            error: nil, link: nil
        ),
        // Palette 4 (Dark/Teal)
        ColorTheme(
            name: "DarkTeal",
            background: Color(red: 57/255, green: 62/255, blue: 70/255),     // #393E46
            tabBar: Color(red: 238/255, green: 238/255, blue: 238/255),     // #EEEEEE
            accent: Color(red: 0/255, green: 173/255, blue: 181/255),       // #00ADB5
            text: Color(red: 34/255, green: 40/255, blue: 49/255),          // #222831
            secondary: Color(red: 238/255, green: 238/255, blue: 238/255),  // #EEEEEE
            error: nil, link: nil
        ),
        // Palette 5 (Beige)
        ColorTheme(
            name: "Beige",
            background: Color(red: 206/255, green: 171/255, blue: 147/255),  // #CEAB93
            tabBar: Color(red: 255/255, green: 251/255, blue: 233/255),     // #FFFBE9
            accent: Color(red: 173/255, green: 139/255, blue: 115/255),     // #AD8B73
            text: Color(red: 227/255, green: 202/255, blue: 165/255),       // #E3CAA5
            secondary: Color(red: 227/255, green: 202/255, blue: 165/255),  // #E3CAA5
            error: nil, link: nil
        ),
        // Palette 6 (Dusty Blue/Beige)
        ColorTheme(
            name: "DustyBlueBeige",
            background: Color(red: 183/255, green: 196/255, blue: 207/255),  // #B7C4CF
            tabBar: Color(red: 238/255, green: 227/255, blue: 203/255),     // #EEE3CB
            accent: Color(red: 215/255, green: 192/255, blue: 174/255),     // #D7C0AE
            text: Color(red: 150/255, green: 126/255, blue: 118/255),       // #967E76
            secondary: Color(red: 215/255, green: 192/255, blue: 174/255),  // #D7C0AE
            error: nil, link: nil
        ),
        // Palette 7 (Cyberpunk)
        ColorTheme(
            name: "Cyberpunk",
            background: Color(hex: "#0A0A0F"), // Deep black-blue       // #0A0A0F
            tabBar: Color(hex: "#16161A"),    // Surface card            // #16161A
            accent: Color(hex: "#7F5AF0"),    // Cyberpunk violet        // #7F5AF0
            text: Color(hex: "#F8F8F2"),      // Off-white                // #F8F8F2
            secondary: Color(hex: "#94A1B2"), // Muted text                // #94A1B2
            error: Color(hex: "#EF4565"),     // Error/alert              // #EF4565
            link: Color(hex: "#00BFFF")       // Link color                // #00BFFF
        )
    ]

    var current: ColorTheme { themes[currentThemeIndex % themes.count] }

    func nextTheme() {
        currentThemeIndex = (currentThemeIndex + 1) % themes.count
    }
} 