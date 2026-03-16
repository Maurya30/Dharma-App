import SwiftUI

// MARK: - Dharma Design System
// All colours, fonts, and spacing live here.
// To change the look of the app, edit this file only.

extension Color {
    static let dharmaGold          = Color(red: 0.957, green: 0.663, blue: 0.208)
    static let dharmaGoldMuted     = Color(red: 0.957, green: 0.663, blue: 0.208).opacity(0.2)
    static let dharmaBackground    = Color(UIColor.systemBackground)
    static let dharmaSurface       = Color(UIColor.secondarySystemBackground)
    static let dharmaSurface2      = Color(UIColor.tertiarySystemBackground)
    static let dharmaTextPrimary   = Color(UIColor.label)
    static let dharmaTextSecondary = Color(UIColor.secondaryLabel)
    static let dharmaTextMuted     = Color(UIColor.tertiaryLabel)
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
        // Serif feels right for Sanskrit/scripture text
        .system(size: size, weight: .regular, design: .serif)
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
