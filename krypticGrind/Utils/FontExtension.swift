import SwiftUI

extension Font {
    static func fabrizio(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return .custom("Fabrizio-Bold", size: size)
        case .medium:
            return .custom("Fabrizio-Medium", size: size)
        default:
            return .custom("Fabrizio-Regular", size: size)
        }
    }
    
    // Predefined sizes for consistency
    static let fabrizioLargeTitle = fabrizio(size: 34, weight: .bold)
    static let fabrizioTitle = fabrizio(size: 28, weight: .bold)
    static let fabrizioTitle2 = fabrizio(size: 22, weight: .medium)
    static let fabrizioTitle3 = fabrizio(size: 20, weight: .medium)
    static let fabrizioHeadline = fabrizio(size: 17, weight: .medium)
    static let fabrizioBody = fabrizio(size: 17, weight: .regular)
    static let fabrizioCallout = fabrizio(size: 16, weight: .regular)
    static let fabrizioSubheadline = fabrizio(size: 15, weight: .regular)
    static let fabrizioFootnote = fabrizio(size: 13, weight: .regular)
    static let fabrizioCaption = fabrizio(size: 12, weight: .regular)
    static let fabrizioCaption2 = fabrizio(size: 11, weight: .regular)
}

// Extension to register fonts
extension Font {
    static func registerFonts() {
        guard let fontURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") else {
            print("Failed to find font files")
            return
        }
        
        for fontURL in fontURLs {
            guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
                  let font = CGFont(fontDataProvider) else {
                print("Failed to load font: \(fontURL.lastPathComponent)")
                continue
            }
            
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterGraphicsFont(font, &error) {
                print("Failed to register font: \(fontURL.lastPathComponent), error: \(error?.takeRetainedValue() ?? "unknown error" as CFError)")
            } else {
                print("Successfully registered font: \(fontURL.lastPathComponent)")
            }
        }
    }
} 