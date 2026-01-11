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
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
        }
    }
}

struct SocialLoginButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SocialLoginButton(
                title: "Continue with Google",
                iconName: "globe", // Placeholder for Google Icon
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
