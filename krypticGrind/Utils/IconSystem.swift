import SwiftUI

// Custom icon system that matches Phosphor style
// You can replace these with actual Phosphor icons once SPM is added
struct AppIcon: View {
    let name: IconName
    let size: CGFloat
    let color: Color
    
    init(_ name: IconName, size: CGFloat = 24, color: Color = .primary) {
        self.name = name
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: name.sfSymbolName)
            .font(.system(size: size, weight: .medium))
            .foregroundColor(color)
    }
}

enum IconName {
    case search
    case brain
    case trophy
    case star
    case bookmark
    case video
    case gear
    case speaker
    case house
    case chart
    case target
    case note
    case play
    case pause
    case stop
    case settings
    case home
    case contest
    case practice
    case leaderboard
    case profile
    case notification
    case close
    case chevronRight
    case chevronLeft
    case chevronDown
    case chevronUp
    
    var sfSymbolName: String {
        switch self {
        case .search: return "magnifyingglass"
        case .brain: return "brain.head.profile"
        case .trophy: return "trophy"
        case .star: return "star.fill"
        case .bookmark: return "bookmark"
        case .video: return "video"
        case .gear: return "gearshape"
        case .speaker: return "speaker.wave.2"
        case .house: return "house"
        case .chart: return "chart.line.uptrend.xyaxis"
        case .target: return "target"
        case .note: return "note.text"
        case .play: return "play.fill"
        case .pause: return "pause.fill"
        case .stop: return "stop.fill"
        case .settings: return "gearshape"
        case .home: return "house"
        case .contest: return "trophy"
        case .practice: return "target"
        case .leaderboard: return "list.number"
        case .profile: return "person.circle"
        case .notification: return "bell"
        case .close: return "xmark"
        case .chevronRight: return "chevron.right"
        case .chevronLeft: return "chevron.left"
        case .chevronDown: return "chevron.down"
        case .chevronUp: return "chevron.up"
        }
    }
}

// Convenience extensions for common icon sizes
extension AppIcon {
    static func small(_ name: IconName, color: Color = .primary) -> AppIcon {
        AppIcon(name, size: 16, color: color)
    }
    
    static func medium(_ name: IconName, color: Color = .primary) -> AppIcon {
        AppIcon(name, size: 20, color: color)
    }
    
    static func large(_ name: IconName, color: Color = .primary) -> AppIcon {
        AppIcon(name, size: 24, color: color)
    }
    
    static func xlarge(_ name: IconName, color: Color = .primary) -> AppIcon {
        AppIcon(name, size: 32, color: color)
    }
}

// Button wrapper for icons
struct IconButton: View {
    let icon: IconName
    let size: CGFloat
    let color: Color
    let action: () -> Void
    
    init(_ icon: IconName, size: CGFloat = 24, color: Color = .primary, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            AppIcon(icon, size: size, color: color)
        }
    }
} 