import SwiftUI
import UIKit

/// Centralized UIKit haptic feedback with prepared generators.
struct HapticManager {
    private init() {}

    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selectionGen = UISelectionFeedbackGenerator()

    static func light() {
        lightImpact.prepare()
        lightImpact.impactOccurred()
    }

    static func medium() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    /// Softer light impact (e.g. locked path node — gentle “no”).
    static func softLight() {
        lightImpact.prepare()
        lightImpact.impactOccurred(intensity: 0.35)
    }

    static func success() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    static func warning() {
        notification.prepare()
        notification.notificationOccurred(.warning)
    }

    static func selection() {
        selectionGen.prepare()
        selectionGen.selectionChanged()
    }
}

extension View {
    /// Selection-style haptic when navigating to a scripture detail from the library list.
    func scriptureNavigationSelectionHaptic() -> some View {
        simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticManager.selection()
            }
        )
    }
}
