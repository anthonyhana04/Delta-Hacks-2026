import SwiftUI

struct SocialLoginButton: View {
    let title: String
    let iconName: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if iconName == "google" {
                    // Custom Google Logo (Angular Gradient for segments)
                    Text("G")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .overlay(
                            AngularGradient(
                                colors: [.red, .yellow, .green, .blue, .red],
                                center: .center,
                                startAngle: .degrees(-90),  // Starts at Top (12 o'clock)
                                endAngle: .degrees(270)  // Ends at Top (complete circle)
                            )
                            .mask(
                                Text("G")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                            )
                        )
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)  // Fixed height for consistency
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct SocialLoginButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SocialLoginButton(
                title: "Continue with Google",
                iconName: "globe",  // Placeholder for Google Icon
                backgroundColor: .white,
                foregroundColor: .black,
                action: {}
            )
            .padding()

            SocialLoginButton(
                title: "Continue with Apple",
                iconName: "applelogo",
                backgroundColor: .black,
                foregroundColor: .white,
                action: {}
            )
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}
