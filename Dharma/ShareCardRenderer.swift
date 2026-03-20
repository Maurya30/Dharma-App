import SwiftUI
import UIKit

enum ShareCardRenderer {
    static func render(_ item: ScriptureItem, size: ShareCardSize, colorScheme: ColorScheme) -> UIImage? {
        if #available(iOS 16.0, *) {
            let view = ShareCardView(item: item, size: size).environment(\.colorScheme, colorScheme)
            let renderer = ImageRenderer(content: view)
            // Render at 1pt == 1px so sizes like 1080x1080pt match pixel-perfect output.
            renderer.scale = 1
            renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
            return renderer.uiImage
        } else {
            return nil
        }
    }

    static func renderSquareAndTall(_ item: ScriptureItem, colorScheme: ColorScheme) -> [UIImage] {
        var images: [UIImage] = []
        if let square = render(item, size: .square, colorScheme: colorScheme) {
            images.append(square)
        }
        if let tall = render(item, size: .tall, colorScheme: colorScheme) {
            images.append(tall)
        }
        return images
    }
}

