import SwiftUI

struct DharmaErrorBanner: View {
    let message: String
    var systemImage: String = "wifi.exclamationmark"
    var isDismissable: Bool = true
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .foregroundColor(Color.dharmaGold)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color.dharmaTextPrimary)
                .lineLimit(2)

            Spacer()

            if isDismissable {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(Color.dharmaTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.dharmaGold.opacity(0.4))
                .frame(height: 1)
        }
    }
}

extension View {
    func dharmaErrorBanner(
        message: String?,
        onDismiss: @escaping () -> Void,
        systemImage: String = "wifi.exclamationmark",
        isDismissable: Bool = true
    ) -> some View {
        overlay(alignment: .top) {
            Group {
                if let message {
                    VStack(spacing: 0) {
                        DharmaErrorBanner(
                            message: message,
                            systemImage: systemImage,
                            isDismissable: isDismissable,
                            onDismiss: onDismiss
                        )
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .safeAreaPadding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: message != nil)
        }
    }
}
