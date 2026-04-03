import AuthenticationServices
import SwiftUI

struct SignInView: View {
    var onFinished: () -> Void

    @ObservedObject private var auth = AuthManager.shared

    var body: some View {
        ZStack {
            Color.clear
                .dharmaBackground()

            VStack(spacing: 0) {
                Spacer(minLength: DharmaSpacing.xl)

                Text("ॐ")
                    .font(.system(size: 64, design: .serif))
                    .foregroundColor(Color(hex: "C9821E"))

                Text("Save your journey")
                    .font(DharmaFont.title(28))
                    .foregroundColor(.dharmaTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, DharmaSpacing.lg)

                Text("Sign in to sync your practice across devices and never lose your progress.")
                    .font(DharmaFont.body(16))
                    .foregroundColor(.dharmaTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DharmaSpacing.xl)
                    .padding(.top, DharmaSpacing.sm)

                Spacer(minLength: DharmaSpacing.xl)

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                            return
                        }
                        Task {
                            await auth.signInWithApple(credential: credential)
                            await MainActor.run {
                                if auth.isSignedIn {
                                    onFinished()
                                }
                            }
                        }
                    case .failure(let error):
                        print("Sign in with Apple: \(error.localizedDescription)")
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)

                Button {
                    HapticManager.light()
                    auth.continueAsGuest()
                    onFinished()
                } label: {
                    HStack(spacing: 4) {
                        Text("Continue as guest")
                            .font(DharmaFont.body(15))
                        Text("→")
                            .font(DharmaFont.body(15))
                    }
                    .foregroundColor(Color(hex: "C9821E").opacity(0.85))
                }
                .buttonStyle(.plain)
                .padding(.top, DharmaSpacing.lg)

                Spacer()

                Text("Your data is encrypted and never sold.")
                    .font(DharmaFont.body(12))
                    .foregroundColor(.dharmaTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DharmaSpacing.lg)
                    .padding(.bottom, DharmaSpacing.xl)
            }

            if auth.isLoading {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.dharmaGold)
            }
        }
    }
}
