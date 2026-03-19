import SwiftUI
import UIKit

// MARK: - Dharma Design System
// Adaptive light/dark color tokens. Light = warm parchment, Dark = deep charcoal.

private func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
}

private func adaptiveUIColor(light: UIColor, dark: UIColor) -> UIColor {
    UIColor { $0.userInterfaceStyle == .dark ? dark : light }
}

extension Color {
    // Saffron accent — same in both modes
    static let dharmaGold = Color(red: 0.788, green: 0.510, blue: 0.118) // #C9821E
    static let dharmaGoldMuted = Color(red: 0.788, green: 0.510, blue: 0.118).opacity(0.2)

    // Backgrounds
    static let dharmaBackground = adaptiveColor(
        light: UIColor(red: 0.980, green: 0.965, blue: 0.929, alpha: 1), // #FAF6ED
        dark:  UIColor(red: 0.051, green: 0.051, blue: 0.051, alpha: 1)  // #0D0D0D
    )
    static let dharmaSurface = adaptiveColor(
        light: UIColor(red: 1.000, green: 0.992, blue: 0.969, alpha: 1), // #FFFDF7
        dark:  UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1)  // #1A1A1A
    )
    static let dharmaSurface2 = adaptiveColor(
        light: UIColor(red: 0.965, green: 0.953, blue: 0.922, alpha: 1),
        dark:  UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1)  // #222222
    )

    // Text
    static let dharmaTextPrimary = adaptiveColor(
        light: UIColor(red: 0.165, green: 0.102, blue: 0.000, alpha: 1), // #2A1A00
        dark:  UIColor(red: 0.961, green: 0.902, blue: 0.784, alpha: 1)  // #F5E6C8
    )
    static let dharmaTextSecondary = adaptiveColor(
        light: UIColor(red: 0.604, green: 0.478, blue: 0.251, alpha: 1), // #9A7A40
        dark:  UIColor(red: 0.541, green: 0.478, blue: 0.353, alpha: 1)  // #8A7A5A
    )
    static let dharmaTextMuted = adaptiveColor(
        light: UIColor(red: 0.604, green: 0.478, blue: 0.251, alpha: 0.6),
        dark:  UIColor(red: 0.541, green: 0.478, blue: 0.353, alpha: 0.6)
    )
    static let dharmaTextBody = adaptiveColor(
        light: UIColor(red: 0.165, green: 0.102, blue: 0.000, alpha: 1), // #2A1A00
        dark:  UIColor(red: 0.831, green: 0.769, blue: 0.627, alpha: 1)  // #D4C4A0
    )

    // Speaker badge
    static let dharmaSpeakerText = adaptiveColor(
        light: UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 1), // #C9821E
        dark:  UIColor(red: 0.961, green: 0.753, blue: 0.416, alpha: 1)  // #F5C06A
    )
    static let dharmaSpeakerBg = adaptiveColor(
        light: UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.08),
        dark:  UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.20)
    )

    // Borders & dividers
    static let dharmaCardBorder = adaptiveColor(
        light: UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.25),
        dark:  UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.15)
    )
    static let dharmaTabBorder = adaptiveColor(
        light: UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.15),
        dark:  UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.10)
    )
    static let dharmaDivider = adaptiveColor(
        light: UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.15),
        dark:  UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.08)
    )

    // Category accents — same in both modes
    static let categoryGita       = Color(red: 0.729, green: 0.459, blue: 0.090)
    static let categoryUpanishads = Color(red: 0.325, green: 0.294, blue: 0.718)
    static let categoryMantras    = Color(red: 0.059, green: 0.431, blue: 0.337)
    static let categoryBhajans    = Color(red: 0.600, green: 0.208, blue: 0.337)
}

// MARK: - UIColor accessors (for UIKit appearance APIs)
extension UIColor {
    static let dharmaBackgroundUI = adaptiveUIColor(
        light: UIColor(red: 0.980, green: 0.965, blue: 0.929, alpha: 1),
        dark:  UIColor(red: 0.051, green: 0.051, blue: 0.051, alpha: 1)
    )
    static let dharmaSurfaceUI = adaptiveUIColor(
        light: UIColor(red: 1.000, green: 0.992, blue: 0.969, alpha: 1),
        dark:  UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1)
    )
    static let dharmaTabBorderUI = adaptiveUIColor(
        light: UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.15),
        dark:  UIColor(red: 0.788, green: 0.510, blue: 0.118, alpha: 0.10)
    )
    static let dharmaTextPrimaryUI = adaptiveUIColor(
        light: UIColor(red: 0.165, green: 0.102, blue: 0.000, alpha: 1),
        dark:  UIColor(red: 0.961, green: 0.902, blue: 0.784, alpha: 1)
    )
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
