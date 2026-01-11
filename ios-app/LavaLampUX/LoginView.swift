import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager()
    @State private var isAnimating: Bool = false
    var onLoginSuccess: () -> Void

    var body: some View {
        ZStack {
            // Background
            LavaLampBackground()

            VStack {
                Spacer()

                // Header Content
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)

                    Text("LavaLamp")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Secure. Simple. Yours.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 40)
                .background(.ultraThinMaterial)  // Bubble background
                .colorScheme(.dark)
                .cornerRadius(40)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, 60)

                Spacer()

                // Login Options Card
                VStack(spacing: 20) {
                    Text("Welcome Back")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)  // Centered for better mobile balance
                        .padding(.bottom, 5)

                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.bottom, 5)
                    }

                    // Buttons with constrained width
                    VStack(spacing: 16) {
                        SocialLoginButton(
                            title: "Continue with Google",
                            iconName: "globe",
                            backgroundColor: .white,
                            foregroundColor: .black,
                            action: {
                                print("Google Login Tapped")
                                authManager.signInWithGoogle()
                            }
                        )

                        SocialLoginButton(
                            title: "Continue with Apple",
                            iconName: "applelogo",
                            backgroundColor: Color(white: 0.2),
                            foregroundColor: .white,
                            action: {
                                print("Apple Login Tapped")
                                onLoginSuccess()
                            }
                        )
                    }
                    .padding(.horizontal, 40)  // Increased padding to make buttons narrower

                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.3))
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 40)  // Match button width constraint

                    Button(action: {
                        print("Create Account / Login Email Tapped")
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Log In with Email")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(Color(red: 0.8, green: 0.9, blue: 1.0))  // Lighter (Pastel Blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.15))  // Darker (Deep dark gray/navy)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 40)  // Alignment with other buttons
                }
                .padding(.vertical, 30)  // Reduced internal vertical padding
                .padding(.horizontal, 20)  // Reduced internal horizontal padding slightly
                .background(.ultraThinMaterial)
                .colorScheme(.dark)
                .cornerRadius(30)
                .padding(.horizontal, 40)  // Increased outer horizontal padding for slimmer card appearance
                .padding(.bottom, 40)
                // Removed shadow as requested
            }
        }
        .onChange(of: authManager.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                onLoginSuccess()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLoginSuccess: {})
    }
}
