import SwiftUI

// MARK: - Dharma Design System

extension Color {
    // Saffron accent
    static let dharmaGold          = Color(red: 0.788, green: 0.510, blue: 0.118) // #C9821E
    static let dharmaGoldMuted     = Color(red: 0.788, green: 0.510, blue: 0.118).opacity(0.2)

    // Backgrounds
    static let dharmaBackground    = Color(red: 0.980, green: 0.965, blue: 0.929) // #FAF6ED warm parchment
    static let dharmaSurface       = Color(red: 1.000, green: 0.992, blue: 0.969) // #FFFDF7 card surface
    static let dharmaSurface2      = Color(red: 0.965, green: 0.953, blue: 0.922) // slightly deeper parchment

    // Text
    static let dharmaTextPrimary   = Color(red: 0.165, green: 0.102, blue: 0.000) // #2A1A00
    static let dharmaTextSecondary = Color(red: 0.604, green: 0.478, blue: 0.251) // #9A7A40
    static let dharmaTextMuted     = Color(red: 0.604, green: 0.478, blue: 0.251).opacity(0.6)

    // Borders
    static let dharmaCardBorder    = Color(red: 0.788, green: 0.510, blue: 0.118).opacity(0.25)
    static let dharmaTabBorder     = Color(red: 0.788, green: 0.510, blue: 0.118).opacity(0.15)

    // Category accents
    static let categoryGita        = Color(red: 0.729, green: 0.459, blue: 0.090)
    static let categoryUpanishads  = Color(red: 0.325, green: 0.294, blue: 0.718)
    static let categoryMantras     = Color(red: 0.059, green: 0.431, blue: 0.337)
    static let categoryBhajans     = Color(red: 0.600, green: 0.208, blue: 0.337)
}

// MARK: - Typography
struct DharmaFont {
    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }
    static func heading(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func sanskrit(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
    static func georgia(_ size: CGFloat = 14) -> Font {
        .custom("Georgia", size: size)
    }
}

// MARK: - Spacing
struct DharmaSpacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct DharmaRadius {
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 24
}
