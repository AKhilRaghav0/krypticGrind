import SwiftUI

// Simple wrapper for SF Symbols
struct AppIcon: View {
    let systemName: String
    let size: CGFloat
    let color: Color
    
    init(_ systemName: String, size: CGFloat = 24, color: Color = .primary) {
        self.systemName = systemName
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .medium))
            .foregroundColor(color)
    }
}

// Button wrapper for icons
struct IconButton: View {
    let systemName: String
    let size: CGFloat
    let color: Color
    let action: () -> Void
    
    init(_ systemName: String, size: CGFloat = 24, color: Color = .primary, action: @escaping () -> Void) {
        self.systemName = systemName
        self.size = size
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            AppIcon(systemName, size: size, color: color)
        }
    }
} 