import SwiftUI

extension Font {
    static func ttphobos(size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        switch (weight, italic) {
        case (.bold, true):
            return .custom("TTPhobosTrial-BoldItalic", size: size)
        case (.bold, false):
            return .custom("TTPhobosTrial-Bold", size: size)
        case (.semibold, _):
            return .custom("TTPhobosTrial-DemiBold", size: size)
        case (.light, _):
            return .custom("TTPhobosTrial-Light", size: size)
        case (_, true):
            return .custom("TTPhobosTrial-Italic", size: size)
        default:
            return .custom("TTPhobosTrial-Regular", size: size)
        }
    }
    
    // Predefined sizes for consistency
    static let ttphobosLargeTitle = ttphobos(size: 34, weight: .bold)
    static let ttphobosTitle = ttphobos(size: 28, weight: .bold)
    static let ttphobosTitle2 = ttphobos(size: 22, weight: .semibold)
    static let ttphobosTitle3 = ttphobos(size: 20, weight: .semibold)
    static let ttphobosHeadline = ttphobos(size: 17, weight: .semibold)
    static let ttphobosBody = ttphobos(size: 17, weight: .regular)
    static let ttphobosCallout = ttphobos(size: 16, weight: .regular)
    static let ttphobosSubheadline = ttphobos(size: 15, weight: .regular)
    static let ttphobosFootnote = ttphobos(size: 13, weight: .regular)
    static let ttphobosCaption = ttphobos(size: 12, weight: .regular)
    static let ttphobosCaption2 = ttphobos(size: 11, weight: .regular)
    static let ttphobosItalicBody = ttphobos(size: 17, weight: .regular, italic: true)
    static let ttphobosBoldItalic = ttphobos(size: 17, weight: .bold, italic: true)
}

// Extension to register fonts
extension Font {
    static func registerFonts() {
        guard let fontURLs = Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: "Fonts") else {
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
                if let error = error?.takeRetainedValue() {
                    print("Failed to register font: \(fontURL.lastPathComponent), error: \(error)")
                } else {
                    print("Failed to register font: \(fontURL.lastPathComponent), unknown error")
                }
            } else {
                print("Successfully registered font: \(fontURL.lastPathComponent)")
            }
        }
    }
} 