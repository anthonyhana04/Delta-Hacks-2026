import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isAnimating: Bool = false

    var body: some View {
        ZStack {
            // Background
            LavaLampBackground()

            VStack {
                Spacer()

                // Logo Container
                VStack(spacing: 20) {
                    Image("LavaLockLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 420, height: 420)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 130)

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
                            iconName: "google",
                            backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.15),
                            foregroundColor: .white,
                            action: {
                                print("Google Login Tapped")
                                authManager.signInWithGoogle()
                            }
                        )

                        SocialLoginButton(
                            title: "Continue with Apple",
                            iconName: "applelogo",
                            backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.15),
                            foregroundColor: .white,
                            action: {
                                print("Apple Login Tapped")
                                // For Apple Login, we traditionally might toggle isLoggedIn manually if not fully implemented like Google
                                // authManager.isLoggedIn = true
                            }
                        )
                    }
                    .padding(.horizontal, 0)  // Full width allowed within card padding

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
                    .padding(.horizontal, 0)

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
                    .padding(.horizontal, 0)
                }
                .padding(.vertical, 30)  // Reduced internal vertical padding
                .padding(.horizontal, 20)  // Reduced internal horizontal padding slightly
                .background(.ultraThinMaterial)
                .colorScheme(.dark)
                .cornerRadius(30)
                .padding(.horizontal, 24)  // Extended closer to edges
                .padding(.bottom, 120)  // Increased padding to push the block higher
                // Removed shadow as requested
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}
